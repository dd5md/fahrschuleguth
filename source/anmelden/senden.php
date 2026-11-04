<?php
declare(strict_types=1);

/**
 * Anmeldeformular der Fahrschule Guth.
 *
 * Prüft die Eingaben und schickt sie per E-Mail an die Fahrschule (PHP mail()).
 * Es wird nichts in einer Datenbank gespeichert. Für den Spam-Schutz gibt es ein verstecktes
 * Feld (Honeypot) und eine Mengenbegrenzung pro IP-Hash (höchstens eine Stunde im Temp-Ordner).
 */

// ---- Einstellungen --------------------------------------------------------
const MAIL_TO = 'uli@fahrschuleguth.de';          // Empfänger der Anmeldungen
const MAIL_FROM = 'noreply@fahrschuleguth.de';    // Absender: Adresse der eigenen Domain (Hoster verlangt das meist)
const MAX_PER_HOUR = 5;                            // Anfragen pro IP und Stunde
const SUCCESS_URL = '/anmelden/danke/';
const FORM_URL = '/anmelden/';
const CLASSES = [
    'Klasse B (Pkw)', 'BF17 (Führerschein ab 17)', 'B96 / B196', 'AM (Moped)',
    'A1 (Leichtkraftrad)', 'A2', 'A', 'Weiß ich noch nicht',
];

header('X-Robots-Tag: noindex');
header('Cache-Control: no-store');

function redirect(string $url): never
{
    header('Location: ' . $url, true, 303);
    exit;
}

/** Einfache Fehlerseite (funktioniert auch ohne JavaScript). */
function fail(int $status, string $message): never
{
    http_response_code($status);
    $message = htmlspecialchars($message, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    echo '<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<meta name="robots" content="noindex"><title>Anfrage nicht gesendet</title>'
        . '<style>body{font:18px/1.5 system-ui,sans-serif;background:#17181c;color:#f4f4f6;margin:0;display:grid;min-height:100vh;place-items:center;padding:1.5rem}'
        . 'main{max-width:34rem}h1{font-size:2rem;letter-spacing:-.03em;margin:0 0 .5rem}a{color:#c4ff4e}</style></head><body><main>'
        . '<h1>Das hat nicht geklappt</h1><p>' . $message . '</p>'
        . '<p>Bitte versuche es noch einmal oder ruf uns an: <a href="tel:+491722336660">0172 | 233 666 0</a>.</p>'
        . '<p><a href="' . FORM_URL . '">Zurück zum Formular</a></p></main></body></html>';
    exit;
}

/** Text bereinigen: Steuerzeichen raus, zuschneiden, Länge begrenzen. */
function clean(mixed $value, int $max, bool $multiline = false): string
{
    $text = is_string($value) ? $value : '';
    $text = str_replace("\0", '', $text);
    $text = $multiline
        ? preg_replace('/[^\P{C}\n]/u', '', str_replace("\r\n", "\n", $text))
        : preg_replace('/\p{C}+/u', ' ', $text);
    $text = trim((string) $text);
    return mb_substr($text, 0, $max, 'UTF-8');
}

// ---- Nur POST --------------------------------------------------------------
if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    redirect(FORM_URL);
}

// Honeypot: Menschen sehen das Feld nicht. Bots füllen es aus und bekommen scheinbar Erfolg.
if (clean($_POST['website'] ?? '', 200) !== '') {
    redirect(SUCCESS_URL);
}

// ---- Mengenbegrenzung pro IP-Hash ----------------------------------------
$ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
$rateFile = sys_get_temp_dir() . '/guth_form_' . hash('sha256', $ip . '|' . __FILE__);
$now = time();
$times = [];
if (is_file($rateFile)) {
    $times = array_filter(array_map('intval', explode("\n", (string) file_get_contents($rateFile))),
        static fn (int $t): bool => $t > $now - 3600);
}
if (count($times) >= MAX_PER_HOUR) {
    fail(429, 'Es wurden in der letzten Stunde zu viele Anfragen gesendet.');
}

// ---- Eingaben prüfen -------------------------------------------------------
$vorname = clean($_POST['vorname'] ?? '', 80);
$nachname = clean($_POST['nachname'] ?? '', 80);
$telefon = clean($_POST['telefon'] ?? '', 40);
$email = clean($_POST['email'] ?? '', 120);
$klasse = clean($_POST['klasse'] ?? '', 60);
$nachricht = clean($_POST['nachricht'] ?? '', 3000, true);

if ($vorname === '' || $nachname === '' || $telefon === '') {
    fail(400, 'Bitte Vorname, Nachname und Telefonnummer ausfüllen.');
}
if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || preg_match('/[\r\n]/', $email)) {
    fail(400, 'Die E-Mail-Adresse sieht nicht richtig aus.');
}
if (!preg_match('/^[0-9 +\-\/().|]{5,40}$/', $telefon)) {
    fail(400, 'Die Telefonnummer sieht nicht richtig aus.');
}
if (!in_array($klasse, CLASSES, true)) {
    $klasse = 'Weiß ich noch nicht';
}
if (!isset($_POST['einwilligung'])) {
    fail(400, 'Bitte stimme der Verarbeitung deiner Angaben zu (Häkchen).');
}

// ---- E-Mail senden -------------------------------------------------------
$subject = mb_encode_mimeheader('Anmeldung über die Website: ' . $vorname . ' ' . $nachname, 'UTF-8', 'B', "\r\n");
$body = "Neue Anmeldung über fahrschuleguth.de\n\n"
    . "Name:       $vorname $nachname\n"
    . "Telefon:    $telefon\n"
    . "E-Mail:     $email\n"
    . "Führerschein: $klasse\n\n"
    . "Nachricht:\n" . ($nachricht !== '' ? $nachricht : '(keine)') . "\n\n"
    . 'Einwilligung zur Verarbeitung per Häkchen erteilt am ' . date('d.m.Y H:i') . " Uhr.\n";

// Anzeigename für Reply-To: nur Buchstaben, Ziffern und einfache Zeichen (keine Sonderzeichen im Header)
$replyName = trim((string) preg_replace('/[^\p{L}\p{N} .\-\']+/u', '', $vorname . ' ' . $nachname));
$replyTo = $replyName !== ''
    ? mb_encode_mimeheader($replyName, 'UTF-8', 'B', "\r\n") . ' <' . $email . '>'
    : $email;
$headers = [
    'From' => 'Fahrschule Guth Website <' . MAIL_FROM . '>',
    'Reply-To' => $replyTo,
    'MIME-Version' => '1.0',
    'Content-Type' => 'text/plain; charset=UTF-8',
    'Content-Transfer-Encoding' => '8bit',
];

$sent = mail(MAIL_TO, $subject, $body, $headers, '-f' . MAIL_FROM);
if (!$sent) {
    fail(500, 'Die Nachricht konnte gerade nicht versendet werden.');
}

$times[] = $now;
@file_put_contents($rateFile, implode("\n", $times), LOCK_EX);
redirect(SUCCESS_URL);
