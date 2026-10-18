import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { modifier } from "ember-modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

const MODES = {
  af: {
    titleKey: "js.anonymous_feedback.title_af",
    unlockUrl: "/anonymous-feedback/unlock",
    sendUrl: "/anonymous-feedback",
    subjectSetting: "anonymous_feedback_subject_placeholder",
    messageSetting: "anonymous_feedback_message_placeholder",
    copyHint: true,
  },
  wb: {
    titleKey: "js.anonymous_feedback.title_wb",
    unlockUrl: "/white-board/unlock",
    sendUrl: "/white-board",
    subjectSetting: "white_board_subject_placeholder",
    messageSetting: "white_board_message_placeholder",
    copyHint: true,
  },
  afva: {
    titleKey: "js.anonymous_feedback.title_afva",
    unlockUrl: "/afva/unlock",
    sendUrl: "/afva",
    subjectSetting: "afva_subject_placeholder",
    messageSetting: "afva_message_placeholder",
    // Optional: Titel aus den Settings (DE / EN in einem Feld), leer = titleKey
    titleSetting: "afva_title",
    // Optional: aus = Seite zeigt nur Titel und Hinweis, kein Formular
    activeSetting: "afva_form_active",
  },
};

// Passt die Höhe der Textarea an den Bildschirm an: sie füllt den Platz bis
// zum unteren Rand, sodass der Senden-Button gerade noch sichtbar bleibt.
const MIN_TEXTAREA_HEIGHT = 120;
const BOTTOM_PADDING = 24;

const fitToViewport = modifier((element) => {
  const resize = () => {
    const wrap = element.closest(".af-wrap");
    const actions = wrap?.querySelector(".af-actions");
    // Dokument-Offset statt Viewport-Offset, damit Scrollen das Ergebnis nicht verändert
    const top = element.getBoundingClientRect().top + window.scrollY;
    const reserve = (actions?.offsetHeight || 40) + BOTTOM_PADDING;
    const available = window.innerHeight - top - reserve;
    element.style.height = `${Math.max(MIN_TEXTAREA_HEIGHT, available)}px`;
  };

  resize();
  window.addEventListener("resize", resize);

  // Neu berechnen, wenn oberhalb Inhalt dazukommt (z.B. Fehlermeldung)
  let observer;
  const wrap = element.closest(".af-wrap");
  if (wrap && typeof ResizeObserver !== "undefined") {
    observer = new ResizeObserver(resize);
    observer.observe(wrap);
  }

  return () => {
    window.removeEventListener("resize", resize);
    observer?.disconnect();
  };
});

export default class AnonymousFeedbackForm extends Component {
  @service siteSettings;

  @tracked unlocked = false;
  @tracked sending = false;
  @tracked sent = false;
  @tracked error = null;

  @tracked doorCode = "";
  @tracked subject = "";
  @tracked message = "";
  @tracked website = "";

  // Bestätigung nach dem Senden. Nur im Speicher der Komponente, nirgends abgelegt.
  @tracked sentSubject = "";
  @tracked sentMessage = "";
  @tracked sentAt = null;
  @tracked recipient = "";
  @tracked copied = false;

  get config() {
    return MODES[this.args.mode] || MODES.af;
  }

  get title() {
    const titleSetting = this.config.titleSetting;
    const custom = titleSetting ? (this.siteSettings[titleSetting] || "").trim() : "";
    return custom || i18n(this.config.titleKey);
  }

  get active() {
    const activeSetting = this.config.activeSetting;
    return !activeSetting || this.siteSettings[activeSetting];
  }

  get intro() {
    return i18n("js.anonymous_feedback.intro");
  }

  // Bestätigungstexte stehen bewusst in DE und EN gleichzeitig da: anonyme
  // Besucher bekommen die Forensprache, nicht ihre Browsersprache.
  get confirmParams() {
    const d = new Date(this.sentAt);
    const pad = (n) => String(n).padStart(2, "0");
    return {
      date: `${pad(d.getDate())}.${pad(d.getMonth() + 1)}.${d.getFullYear()}`,
      time: `${pad(d.getHours())}:${pad(d.getMinutes())}`,
      recipient: this.recipient,
    };
  }

  get confirmDe() {
    return i18n(`js.anonymous_feedback.confirm.${this.args.mode}_de`, this.confirmParams);
  }

  get confirmEn() {
    return i18n(`js.anonymous_feedback.confirm.${this.args.mode}_en`, this.confirmParams);
  }

  get copyHintDe() {
    return i18n("js.anonymous_feedback.confirm.copy_hint_de", { recipient: this.recipient });
  }

  get copyHintEn() {
    return i18n("js.anonymous_feedback.confirm.copy_hint_en", { recipient: this.recipient });
  }

  get subjectPlaceholder() {
    return this.siteSettings[this.config.subjectSetting];
  }

  get messagePlaceholder() {
    return this.siteSettings[this.config.messageSetting];
  }

  @action
  onDoorCodeKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.unlock();
    }
  }

  @action
  async unlock() {
    this.error = null;

    const code = (this.doorCode || "").trim();
    if (!code) {
      this.error = i18n("js.anonymous_feedback.errors.invalid_code");
      return;
    }

    try {
      await ajax(this.config.unlockUrl, {
        type: "POST",
        data: {
          door_code: code,
          website: this.website,
        },
      });

      this.unlocked = true;
      this.subject = "";
      this.message = "";
      this.website = "";
    } catch (e) {
      this.handleError(e);
    }
  }

  @action
  async send() {
    this.error = null;

    const subject = (this.subject || "").trim();
    const message = (this.message || "").trim();

    if (!subject || !message) {
      this.error = i18n("js.anonymous_feedback.errors.missing_fields");
      return;
    }

    this.sending = true;
    try {
      const result = await ajax(this.config.sendUrl, {
        type: "POST",
        data: {
          subject,
          message,
          website: this.website,
        },
      });

      this.sentSubject = subject;
      this.sentMessage = message;
      this.sentAt = result?.sent_at || new Date().toISOString();
      this.recipient = result?.recipient || "";
      this.copied = false;
      this.sent = true;
      this.unlocked = false;
      this.doorCode = "";
      this.subject = "";
      this.message = "";
      this.website = "";
    } catch (e) {
      this.handleError(e);
    } finally {
      this.sending = false;
    }
  }

  @action
  async copyContent() {
    this.error = null;
    try {
      await navigator.clipboard.writeText(`${this.sentSubject}\n\n${this.sentMessage}`);
      this.copied = true;
    } catch {
      this.error = i18n("js.anonymous_feedback.confirm.copy_failed");
    }
  }

  // Zurück zur Türcode-Eingabe, der gesendete Inhalt wird verworfen
  @action
  newMessage() {
    this.error = null;
    this.sent = false;
    this.copied = false;
    this.sentSubject = "";
    this.sentMessage = "";
    this.sentAt = null;
    this.recipient = "";
  }

  handleError(e) {
    const json = e.jqXHR?.responseJSON;
    if (json?.error_key) {
      this.error = i18n(
        `js.anonymous_feedback.errors.${json.error_key}`,
        json.error_params
      );
    } else {
      this.error = i18n("js.anonymous_feedback.errors.generic");
    }
  }

  <template>
    <div class="af-wrap">
      <h1>{{this.title}}</h1>

      {{#if this.sent}}
        <div class="alert alert-success af-confirm">
          <p>{{this.confirmDe}}</p>
          <p>{{this.confirmEn}}</p>
        </div>

        {{#if this.error}}
          <div class="alert alert-error">{{this.error}}</div>
        {{/if}}

        <label class="control-label">{{i18n "js.anonymous_feedback.confirm.content_label"}}</label>
        <div class="af-sent-content">
          <div class="af-sent-subject">{{this.sentSubject}}</div>
          <div class="af-sent-message">{{this.sentMessage}}</div>
        </div>

        <div class="af-hint">
          <p>
            {{i18n "js.anonymous_feedback.confirm.close_hint_de"}}
            {{#if this.config.copyHint}}{{this.copyHintDe}}{{/if}}
          </p>
          <p>
            {{i18n "js.anonymous_feedback.confirm.close_hint_en"}}
            {{#if this.config.copyHint}}{{this.copyHintEn}}{{/if}}
          </p>
        </div>

        <div class="af-actions">
          <button type="button" class="btn btn-default" {{on "click" this.copyContent}}>
            {{#if this.copied}}
              {{i18n "js.anonymous_feedback.confirm.copied"}}
            {{else}}
              {{i18n "js.anonymous_feedback.confirm.btn_copy"}}
            {{/if}}
          </button>
          <button type="button" class="btn btn-primary" {{on "click" this.newMessage}}>
            {{i18n "js.anonymous_feedback.confirm.btn_new"}}
          </button>
        </div>
      {{else if this.active}}
        <p>{{this.intro}}</p>

        {{#if this.error}}
          <div class="alert alert-error">{{this.error}}</div>
        {{/if}}

        <Input
          @value={{this.website}}
          class="anon-feedback-honeypot"
          @type="text"
          autocomplete="off"
          tabindex="-1"
        />

        {{#unless this.unlocked}}
          <div class="control-group">
            <label class="control-label">{{i18n "js.anonymous_feedback.doorcode_label"}}</label>
            <div class="controls">
              <Input
                @value={{this.doorCode}}
                @type="password"
                class="af-input"
                autocomplete="one-time-code"
                {{on "keydown" this.onDoorCodeKeydown}}
              />
            </div>
          </div>

          <div class="af-actions">
            <button type="button" class="btn btn-primary" {{on "click" this.unlock}}>
              {{i18n "js.anonymous_feedback.btn_next"}}
            </button>
          </div>
        {{else}}
          <div class="control-group">
            <label class="control-label">{{i18n "js.anonymous_feedback.subject_label"}}</label>
            <div class="controls">
              <Input
                @value={{this.subject}}
                class="af-input"
                placeholder={{this.subjectPlaceholder}}
              />
            </div>
          </div>

          <div class="control-group">
            <label class="control-label">{{i18n "js.anonymous_feedback.message_label"}}</label>
            <div class="controls">
              <Textarea
                @value={{this.message}}
                class="af-textarea"
                placeholder={{this.messagePlaceholder}}
                {{fitToViewport}}
              />
            </div>
          </div>

          <div class="af-actions">
            <button
              type="button"
              class="btn btn-primary"
              disabled={{this.sending}}
              {{on "click" this.send}}
            >
              {{#if this.sending}}
                {{i18n "js.anonymous_feedback.sending"}}
              {{else}}
                {{i18n "js.anonymous_feedback.btn_send"}}
              {{/if}}
            </button>
          </div>
        {{/unless}}
      {{else}}
        <div class="alert alert-info">{{i18n "js.anonymous_feedback.inactive"}}</div>
      {{/if}}
    </div>
  </template>
}
