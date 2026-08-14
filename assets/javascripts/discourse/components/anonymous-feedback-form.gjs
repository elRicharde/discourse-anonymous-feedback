import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";

export default class AnonymousFeedbackForm extends Component {
  @tracked unlocked = false;
  @tracked sending = false;
  @tracked sent = false;
  @tracked error = null;

  @tracked doorCode = "";
  @tracked subject = "";
  @tracked message = "";

  @tracked website = "";

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
      await ajax(this.args.unlockUrl, {
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
      await ajax(this.args.sendUrl, {
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
      <h1>{{@title}}</h1>
      <p>{{@intro}}</p>

      {{#if this.error}}
        <div class="alert alert-error">{{this.error}}</div>
      {{/if}}

      {{#if this.sent}}
        <div class="alert alert-success">{{i18n "js.anonymous_feedback.sent"}}</div>
      {{/if}}

      {{! Honeypot: must stay invisible for humans }}
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
              placeholder={{@subjectPlaceholder}}
            />
          </div>
        </div>

        <div class="control-group">
          <label class="control-label">{{i18n "js.anonymous_feedback.message_label"}}</label>
          <div class="controls">
            <Textarea
              @value={{this.message}}
              class="af-textarea"
              placeholder={{@messagePlaceholder}}
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
