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
  },
  wb: {
    titleKey: "js.anonymous_feedback.title_wb",
    unlockUrl: "/white-board/unlock",
    sendUrl: "/white-board",
    subjectSetting: "white_board_subject_placeholder",
    messageSetting: "white_board_message_placeholder",
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

  get config() {
    return MODES[this.args.mode] || MODES.af;
  }

  get title() {
    return i18n(this.config.titleKey);
  }

  get intro() {
    return i18n("js.anonymous_feedback.intro");
  }

  get subjectPlaceholder() {
    return this.siteSettings[this.config.subjectSetting];
  }

  get messagePlaceholder() {
    return this.siteSettings[this.config.messageSetting];
  }

  @action
  async unlock() {
    this.error = null;
    this.sent = false;

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
    this.sent = false;

    const subject = (this.subject || "").trim();
    const message = (this.message || "").trim();

    if (!subject || !message) {
      this.error = i18n("js.anonymous_feedback.errors.missing_fields");
      return;
    }

    this.sending = true;
    try {
      await ajax(this.config.sendUrl, {
        type: "POST",
        data: {
          subject,
          message,
          website: this.website,
        },
      });

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
      <p>{{this.intro}}</p>

      {{#if this.error}}
        <div class="alert alert-error">{{this.error}}</div>
      {{/if}}

      {{#if this.sent}}
        <div class="alert alert-success">{{i18n "js.anonymous_feedback.sent"}}</div>
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
    </div>
  </template>
}
