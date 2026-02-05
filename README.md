# Discourse Anonymous Feedback & White Board

This Discourse plugin provides two independent, anonymous posting forms: "Anonymous Feedback" and "White Board". Both forms are protected by a "door code" (a simple password) and allow users without an account to send a private message to a pre-configured user group.

This is ideal for communities that need a way to receive truly anonymous feedback or want to provide a digital suggestion box.

## Why Use This Plugin?

In many communities, sensitive topics or ideas require a channel for feedback that guarantees anonymity and reduces social pressure. This plugin addresses several key challenges:

-   **Fostering Uninhibited Feedback**: It provides a safe space for users (and even non-users, if the door code is shared externally) to share honest, unfiltered opinions, concerns, or innovative ideas without fear of judgment or repercussions. This can lead to more candid and valuable input that might otherwise be withheld.
-   **Confidentiality and Trust**: By ensuring anonymity through technical measures (like HMAC-based rate limiting without IP logging), the plugin builds trust and encourages broader participation, especially for delicate subjects.
-   **Bridging Communication Gaps**: It creates an accessible communication bridge for individuals who are hesitant to post publicly or who do not have a Discourse account, thereby expanding the reach of community engagement.
-   **Structured Input**: By directing feedback to a specific private group, it ensures that sensitive information is reviewed by the appropriate team members, allowing for focused discussion and action away from public view.
-   **Simplicity for Non-Users**: The door code mechanism allows external parties or temporary visitors to provide input without the overhead of full account registration.

Ultimately, this plugin enhances community interaction by enabling a more inclusive and secure environment for critical discussions and suggestions.

## Example Use Cases / Workflows

This plugin was designed to be flexible. Here are two common workflows you can implement:

### Use Case 1: The "White Board" - A Moderated Public Notice Board

This use case is for creating visibility for sensitive topics or inappropriate behavior that has been observed in the community (e.g., at events or in general interactions).

**The Goal**: To make important issues visible to the community without exposing the identity of the person reporting them. The focus is on the message, not the messenger.

**The Workflow**:
1.  **Submission**: A user submits a post via the `/white-board` form.
2.  **Private Review**: The post arrives as a Private Message to the configured `target_group` (e.g., a moderation team or a "Trust & Safety" committee).
3.  **Vetting**: The team reviews the submission against pre-defined criteria (e.g., no personal attacks, no insults, adherence to community guidelines).
4.  **Publication (If Approved)**: A designated member of the team manually copies the content and creates a new topic in a dedicated, public "White Board" category. This topic is posted using a specific, generic account (e.g., a "WhiteBoardBot" or "Anonymous" user, configured via the `bot_username` setting).
5.  **Discussion Control**: The "White Board" category permissions are set so that only the designated bot account can create posts, and replies are disabled. This ensures the space remains a notice board and prevents public debates that could derail the original message.
6.  **Handling Rejections**: Since there is no way to contact the anonymous sender, it's a good practice to have a pinned topic in the "White Board" category explaining the publication criteria and the reasons why a submission might be rejected.

### Use Case 2: Anonymous Feedback - A Direct, Private Channel

This use case is for providing a direct, confidential line of communication to a specific team for any kind of feedback.

**The Goal**: To give members and non-members a safe way to provide feedback on community matters, votes, or other topics directly to the leadership or a relevant committee.

**The Workflow**:
1.  **Submission**: A user submits feedback via the `/anonymous-feedback` form. The subject line can help categorize the message.
2.  **Private Delivery**: The message arrives as a Private Message to the `target_group`. The subject is prefixed with "af:" to clearly identify its origin.
3.  **Internal Handling**: The team can then discuss the feedback privately, involve other relevant parties if necessary, or decide on a course of action.
4.  **Best Practice for Inappropriate Feedback**: If a submission is inappropriate, the team can simply delete it. You could consider posting a generic, public notice (e.g., in a "News" category) stating that "Feedback received on [Date] was not processed because it violated our community standards for respectful communication." This informs the sender without revealing any details and encourages them to re-submit in a more constructive manner.

## Features

- **Two Independent Endpoints**: Provides `/anonymous-feedback` and `/white-board`, each with its own separate configuration.
- **Door Code Protection**: Each form is protected by its own secret door code to prevent spam.
- **Configurable Target Group**: Messages from each form are sent as a private message to a specific, configurable user group.
- **Single-Use Session**: After a message is successfully sent, the user is returned to the door code screen. They must re-enter the code to send another message, preventing simple multi-post spam.
- **Anonymity-Preserving Rate Limiting**: Protects against brute-force attempts and spam without logging IP addresses. It uses a temporary, anonymous identifier (HMAC with a rotating secret) to track failed attempts.
- **Bot Protection**: Includes a hidden honeypot field to trap simple bots.
- **Custom Posting User**: You can specify a bot user for each form, so the private messages appear to be sent from that user (e.g., "FeedbackBot"). If not specified, it defaults to the system user.
- **Clean, Modern UI**: The forms are built using a reusable Ember.js component for a consistent and clean user experience.

- **Two Independent Endpoints**: Provides `/anonymous-feedback` and `/white-board`, each with its own separate configuration.
- **Door Code Protection**: Each form is protected by its own secret door code to prevent spam.
- **Configurable Target Group**: Messages from each form are sent as a private message to a specific, configurable user group.
- **Anonymity-Preserving Rate Limiting**: Protects against brute-force attempts and spam without logging IP addresses. It uses a temporary, anonymous identifier (HMAC with a rotating secret) to track failed attempts.
- **Bot Protection**: Includes a hidden honeypot field to trap simple bots.
- **Custom Posting User**: You can specify a bot user for each form, so the private messages appear to be sent from that user (e.g., "FeedbackBot"). If not specified, it defaults to the system user.
- **Clean, Modern UI**: The forms are built using a reusable Ember.js component for a consistent and clean user experience.

## Installation

Follow the standard Discourse plugin installation guide: [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157).

1.  Add the plugin's repository URL to your `app.yml` file:
    ```yml
    hooks:
      after_code:
        - exec:
            cd: $home/plugins
            cmd:
              - git clone https://github.com/discourse/discourse-anonymous-feedback.git
    ```
2.  Rebuild your container: `cd /var/discourse && ./launcher rebuild app`

## Configuration

After installation, you can configure the plugin from the Discourse admin settings. Search for "anonymous feedback". All settings are independent for the "Anonymous Feedback" and "White Board" forms.

| Setting                                | Description                                                                                                                              |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `anonymous_feedback_enabled`           | Toggles the `/anonymous-feedback` page on or off.                                                                                        |
| `white_board_enabled`                  | Toggles the `/white-board` page on or off.                                                                                               |
| `... door_code`                        | The secret password users must enter to access the message form.                                                                         |
| `... target_group`                     | The name of the user group that will receive the private messages. This group must exist.                                                |
| `... rate_limit_per_hour`              | A global limit on how many messages can be sent per hour to prevent abuse. Set to `0` to disable.                                          |
| `... max_message_length`               | The maximum number of characters allowed in the message body.                                                                            |
| `... hmac_rotation_hours`              | How often the secret key for rate limiting rotates. A shorter duration resets brute-force lockouts faster but is slightly less secure.     |
| `... bot_username`                     | Optional. The username of the user who will send the PM. The user must exist. If blank, defaults to the system user.                       |

## How It Works (Technical Overview)

The plugin is designed with anonymity and security in mind.

1.  **Access**: A user navigates to `/anonymous-feedback` or `/white-board`.
2.  **Unlock**: The user must enter the correct door code. The server validates this code.
    -   To prevent brute-force attacks, the server uses a rate-limiting system based on an HMAC hash of the user's IP address and a rotating secret. The IP address itself is never stored.
    -   If the code is correct, the server sets a temporary, single-use flag in the user's session.
3.  **Submit**: The user writes and submits their message.
4.  **Create PM**: The server checks for the session flag. If it's valid, it creates a new private message addressed to the configured target group and posts it as the configured bot user (or system user). The session flag is then immediately deleted, requiring the user to enter the door code again for any subsequent message.

## Development / Architecture

-   **Backend**: A single Ruby on Rails controller, `AnonymousFeedbackController`, handles all requests for both endpoints. It uses a `kind` method that checks the request path (`/anonymous-feedback` vs. `/white-board`) to determine which set of configurations to use. This avoids code duplication. A dynamic `setting` helper further simplifies reading the configuration.
-   **Frontend**: The UI is built on a single, reusable Ember.js component, `<AnonymousFeedbackForm />`.
    -   This component contains all the HTML, CSS, and Javascript logic for the form's state (unlocking, sending, error handling).
    -   The route templates (`anonymous-feedback.hbs` and `white-board.hbs`) are now extremely simple. They just instantiate this component and pass in the correct parameters (e.g., title, API URLs). This DRY (Don't Repeat Yourself) approach makes the frontend code clean and easy to maintain.

---

# Discourse Anonymes Feedback & White Board

Dieses Discourse-Plugin stellt zwei unabhängige, anonyme Formulare bereit: "Anonymes Feedback" und "White Board". Beide Formulare sind durch einen "Türcode" (ein einfaches Passwort) geschützt und ermöglichen es Benutzern ohne Account, eine private Nachricht an eine vorkonfigurierte Benutzergruppe zu senden.

Dies ist ideal für Communitys, die eine Möglichkeit benötigen, wirklich anonymes Feedback zu erhalten, oder die einen digitalen Briefkasten bereitstellen möchten.

## Warum dieses Plugin verwenden?

In vielen Communitys erfordern sensible Themen oder Ideen einen Feedback-Kanal, der Anonymität garantiert und sozialen Druck reduziert. Dieses Plugin begegnet mehreren zentralen Herausforderungen:

-   **Förderung ungehemmten Feedbacks**: Es bietet einen sicheren Raum für Benutzer (und sogar Nicht-Benutzer, wenn der Türcode extern geteilt wird), um ehrliche, ungefilterte Meinungen, Bedenken oder innovative Ideen ohne Angst vor Urteilen oder Konsequenzen zu teilen. Dies kann zu offeneren und wertvolleren Beiträgen führen, die sonst möglicherweise zurückgehalten würden.
-   **Vertraulichkeit und Vertrauen**: Durch die Sicherstellung der Anonymität mittels technischer Maßnahmen (wie HMAC-basierter Ratenbegrenzung ohne IP-Protokollierung) schafft das Plugin Vertrauen und fördert eine breitere Teilnahme, insbesondere bei heiklen Themen.
-   **Überbrückung von Kommunikationslücken**: Es schafft eine zugängliche Kommunikationsbrücke für Personen, die zögern, öffentlich zu posten, oder die kein Discourse-Konto besitzen, wodurch die Reichweite des Community-Engagements erweitert wird.
-   **Strukturierte Eingabe**: Durch die Weiterleitung des Feedbacks an eine bestimmte private Gruppe wird sichergestellt, dass sensible Informationen von den entsprechenden Teammitgliedern geprüft werden, was eine fokussierte Diskussion und Maßnahmen abseits der Öffentlichkeit ermöglicht.
-   **Einfachheit für Nicht-Benutzer**: Der Türcode-Mechanismus ermöglicht es externen Parteien oder temporären Besuchern, Beiträge zu leisten, ohne den Aufwand einer vollständigen Kontoregistrierung.

Letztendlich verbessert dieses Plugin die Community-Interaktion, indem es ein inklusiveres und sichereres Umfeld für kritische Diskussionen und Vorschläge schafft.

## Beispiel-Anwendungsfälle / Workflows

Dieses Plugin wurde flexibel gestaltet. Hier sind zwei gängige Workflows, die Sie implementieren können:

### Anwendungsfall 1: Das "Weiße Brett" – Ein moderiertes öffentliches Schwarzes Brett

Dieser Anwendungsfall dient dazu, Sichtbarkeit für sensible Themen oder unangemessenes Verhalten zu schaffen, das in der Community beobachtet wurde (z. B. bei Veranstaltungen oder in allgemeinen Interaktionen).

**Das Ziel**: Wichtige Anliegen für die Community sichtbar zu machen, ohne die Identität der meldenden Person preiszugeben. Der Fokus liegt auf der Nachricht, nicht auf dem Absender.

**Der Workflow**:
1.  **Einreichung**: Ein Benutzer reicht einen Beitrag über das `/white-board`-Formular ein.
2.  **Private Prüfung**: Der Beitrag trifft als private Nachricht bei der konfigurierten `target_group` ein (z. B. einem Moderationsteam oder einem "Trust & Safety"-Komitee).
3.  **Prüfung**: Das Team prüft die Einreichung anhand vordefinierter Kriterien (z. B. keine persönlichen Angriffe, keine Beleidigungen, Einhaltung der Community-Richtlinien).
4.  **Veröffentlichung (falls genehmigt)**: Ein benanntes Mitglied des Teams kopiert den Inhalt manuell und erstellt ein neues Thema in einer dedizierten, öffentlichen Kategorie "Weißes Brett". Dieses Thema wird mit einem spezifischen, generischen Konto gepostet (z. B. einem "WhiteBoardBot" oder "Anonym"-Benutzer, der über die `bot_username`-Einstellung konfiguriert wird).
5.  **Diskussionssteuerung**: Die Berechtigungen der Kategorie "Weißes Brett" werden so eingestellt, dass nur das benannte Bot-Konto Beiträge erstellen kann und Antworten deaktiviert sind. Dadurch wird sichergestellt, dass der Bereich ein Schwarzes Brett bleibt und öffentliche Debatten, die von der ursprünglichen Nachricht ablenken könnten, verhindert werden.
6.  **Umgang mit Ablehnungen**: Da es keine Möglichkeit gibt, den anonymen Absender zu kontaktieren, ist es eine gute Praxis, ein angeheftetes Thema in der Kategorie "Weißes Brett" zu haben, das die Veröffentlichungskriterien und die Gründe, warum ein Beitrag abgelehnt werden könnte, erläutert.

### Anwendungsfall 2: Anonymes Feedback – Ein direkter, privater Kanal

Dieser Anwendungsfall dient dazu, eine direkte, vertrauliche Kommunikationslinie zu einem bestimmten Team für jede Art von Feedback bereitzustellen.

**Das Ziel**: Mitgliedern und Nicht-Mitgliedern eine sichere Möglichkeit zu geben, Feedback zu Community-Angelegenheiten, Abstimmungen oder anderen Themen direkt an die Leitung oder ein zuständiges Komitee zu geben.

**Der Workflow**:
1.  **Einreichung**: Ein Benutzer reicht Feedback über das `/anonymous-feedback`-Formular ein. Die Betreffzeile kann helfen, die Nachricht zu kategorisieren.
2.  **Private Zustellung**: Die Nachricht trifft als private Nachricht bei der `target_group` ein. Der Betreff wird mit "af:" vorangestellt, um die Herkunft klar zu kennzeichnen.
3.  **Interne Bearbeitung**: Das Team kann das Feedback dann privat diskutieren, bei Bedarf andere relevante Parteien einbeziehen oder über das weitere Vorgehen entscheiden.
4.  **Best Practice für unangemessenes Feedback**: Wenn eine Einreichung unangemessen ist, kann das Team sie einfach löschen. Sie könnten in Erwägung ziehen, eine allgemeine, öffentliche Mitteilung zu veröffentlichen (z. B. in einer "Neuigkeiten"-Kategorie), in der es heißt: "Feedback, das am [Datum] eingegangen ist, wurde nicht bearbeitet, da es gegen unsere Community-Standards für respektvolle Kommunikation verstoßen hat." Dies informiert den Absender ohne Details preiszugeben und ermutigt ihn, es auf konstruktivere Weise erneut zu versuchen.

## Funktionen

- **Zwei unabhängige Endpunkte**: Stellt `/anonymous-feedback` und `/white-board` bereit, jeder mit eigener, separater Konfiguration.
- **Schutz durch Türcode**: Jedes Formular ist durch einen eigenen geheimen Türcode geschützt, um Spam zu verhindern.
- **Konfigurierbare Zielgruppe**: Nachrichten aus jedem Formular werden als private Nachricht an eine spezifische, konfigurierbare Benutzergruppe gesendet.
- **Einmalige Sitzung**: Nachdem eine Nachricht erfolgreich gesendet wurde, wird der Benutzer zum Türcode-Bildschirm zurückgeleitet. Er muss den Code erneut eingeben, um eine weitere Nachricht zu senden, was einfaches Multi-Post-Spamming verhindert.
- **Anonymität wahrende Ratenbegrenzung**: Schützt vor Brute-Force-Angriffen und Spam, ohne IP-Adressen zu protokollieren. Es wird ein temporärer, anonymer Bezeichner (HMAC mit einem rotierenden Geheimnis) verwendet, um fehlgeschlagene Versuche zu verfolgen.
- **Bot-Schutz**: Enthält ein verstecktes Honeypot-Feld, um einfache Bots abzufangen.
- **Benutzerdefinierter Absender-Benutzer**: Sie können für jedes Formular einen Bot-Benutzer festlegen, sodass die privaten Nachrichten scheinbar von diesem Benutzer gesendet werden (z. B. "FeedbackBot"). Wenn nicht angegeben, wird standardmäßig der Systembenutzer verwendet.
- **Saubere, moderne Benutzeroberfläche**: Die Formulare basieren auf einer wiederverwendbaren Ember.js-Komponente für eine konsistente und saubere Benutzererfahrung.

- **Zwei unabhängige Endpunkte**: Stellt `/anonymous-feedback` und `/white-board` bereit, jeder mit eigener, separater Konfiguration.
- **Schutz durch Türcode**: Jedes Formular ist durch einen eigenen geheimen Türcode geschützt, um Spam zu verhindern.
- **Konfigurierbare Zielgruppe**: Nachrichten aus jedem Formular werden als private Nachricht an eine spezifische, konfigurierbare Benutzergruppe gesendet.
- **Anonymität wahrende Ratenbegrenzung**: Schützt vor Brute-Force-Angriffen und Spam, ohne IP-Adressen zu protokollieren. Es wird ein temporärer, anonymer Bezeichner (HMAC mit einem rotierenden Geheimnis) verwendet, um fehlgeschlagene Versuche zu verfolgen.
- **Bot-Schutz**: Enthält ein verstecktes Honeypot-Feld, um einfache Bots abzufangen.
- **Benutzerdefinierter Absender-Benutzer**: Sie können für jedes Formular einen Bot-Benutzer festlegen, sodass die privaten Nachrichten scheinbar von diesem Benutzer gesendet werden (z. B. "FeedbackBot"). Wenn nicht angegeben, wird standardmäßig der Systembenutzer verwendet.
- **Saubere, moderne Benutzeroberfläche**: Die Formulare basieren auf einer wiederverwendbaren Ember.js-Komponente für eine konsistente und saubere Benutzererfahrung.

## Installation

Folgen Sie der Standard-Anleitung zur Installation von Discourse-Plugins: [Ein Plugin installieren](https://meta.discourse.org/t/install-a-plugin/19157).

1.  Fügen Sie die Repository-URL des Plugins zu Ihrer `app.yml`-Datei hinzu:
    ```yml
    hooks:
      after_code:
        - exec:
            cd: $home/plugins
            cmd:
              - git clone https://github.com/discourse/discourse-anonymous-feedback.git
    ```
2.  Bauen Sie Ihren Container neu: `cd /var/discourse && ./launcher rebuild app`

## Konfiguration

Nach der Installation können Sie das Plugin in den Discourse-Admin-Einstellungen konfigurieren. Suchen Sie nach "anonymous feedback". Alle Einstellungen sind für die Formulare "Anonymes Feedback" und "White Board" unabhängig.

| Einstellung                            | Beschreibung                                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `anonymous_feedback_enabled`           | Schaltet die Seite `/anonymous-feedback` ein oder aus.                                                                                  |
| `white_board_enabled`                  | Schaltet die Seite `/white-board` ein oder aus.                                                                                         |
| `... door_code`                        | Das geheime Passwort, das Benutzer eingeben müssen, um auf das Nachrichtenformular zuzugreifen.                                           |
| `... target_group`                     | Der Name der Benutzergruppe, die die privaten Nachrichten erhalten soll. Diese Gruppe muss existieren.                                    |
| `... rate_limit_per_hour`              | Ein globales Limit, wie viele Nachrichten pro Stunde gesendet werden können, um Missbrauch zu verhindern. Auf `0` setzen, um zu deaktivieren. |
| `... max_message_length`               | Die maximale Anzahl an Zeichen, die im Nachrichtentext erlaubt sind.                                                                    |
| `... hmac_rotation_hours`              | Wie oft der geheime Schlüssel für die Ratenbegrenzung rotiert. Eine kürzere Dauer setzt Brute-Force-Sperren schneller zurück, ist aber geringfügig weniger sicher. |
| `... bot_username`                     | Optional. Der Benutzername des Benutzers, der die PN senden wird. Der Benutzer muss existieren. Wenn leer, wird der Systembenutzer verwendet. |

## Funktionsweise (Technische Übersicht)

Das Plugin wurde mit Fokus auf Anonymität und Sicherheit entwickelt.

1.  **Zugriff**: Ein Benutzer navigiert zu `/anonymous-feedback` oder `/white-board`.
2.  **Freischalten**: Der Benutzer muss den korrekten Türcode eingeben. Der Server validiert diesen Code.
    -   Um Brute-Force-Angriffe zu verhindern, verwendet der Server ein Ratenbegrenzungssystem, das auf einem HMAC-Hash der IP-Adresse des Benutzers und einem rotierenden Geheimnis basiert. Die IP-Adresse selbst wird niemals gespeichert.
    -   Wenn der Code korrekt ist, setzt der Server ein temporäres, einmalig verwendbares Flag in der Sitzung des Benutzers.
3.  **Absenden**: Der Benutzer schreibt und sendet seine Nachricht.
4.  **PN erstellen**: Der Server prüft das Sitzungs-Flag. Wenn es gültig ist, erstellt er eine neue private Nachricht an die konfigurierte Zielgruppe und postet sie als der konfigurierte Bot-Benutzer (oder Systembenutzer). Das Sitzungs-Flag wird dann sofort gelöscht, sodass der Benutzer für jede weitere Nachricht den Türcode erneut eingeben muss.

## Entwicklung / Architektur

-   **Backend**: Ein einziger Ruby on Rails Controller, `AnonymousFeedbackController`, verarbeitet alle Anfragen für beide Endpunkte. Er verwendet eine `kind`-Methode, die den Anfragepfad (`/anonymous-feedback` vs. `/white-board`) prüft, um zu bestimmen, welche Konfigurationen verwendet werden sollen. Dies vermeidet Code-Duplizierung. Ein dynamischer `setting`-Helfer vereinfacht das Auslesen der Konfiguration zusätzlich.
-   **Frontend**: Die Benutzeroberfläche basiert auf einer einzigen, wiederverwendbaren Ember.js-Komponente, `<AnonymousFeedbackForm />`.
    -   Diese Komponente enthält die gesamte HTML-, CSS- und Javascript-Logik für den Zustand des Formulars (Freischalten, Senden, Fehlerbehandlung).
    -   Die Routen-Templates (`anonymous-feedback.hbs` und `white-board.hbs`) sind jetzt extrem einfach. Sie instanziieren nur noch diese Komponente und übergeben die richtigen Parameter (z. B. Titel, API-URLs). Dieser DRY-Ansatz (Don't Repeat Yourself) macht den Frontend-Code sauber und leicht wartbar.