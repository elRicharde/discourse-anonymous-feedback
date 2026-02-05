import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import I18n from "discourse-i18n";

export default class AnonymousFeedbackForm extends Component {
  // Component State
  @tracked unlocked = false;
  @tracked sending = false;
  @tracked sent = false;
  @tracked error = null;

  // Form Fields
  @tracked doorCode = "";
  @tracked subject = "";
  @tracked message = "";

  // Honeypot (must stay empty)
  @tracked website = "";

  @action
  async unlock() {
    this.error = null;
    this.sent = false;

    const code = (this.doorCode || "").trim();
    if (!code) {
      this.error = I18n.t("js.anonymous_feedback.errors.invalid_code");
      return;
    }

    try {
      await ajax(this.args.unlockUrl, {
        type: "POST",
        data: {
          door_code: code,
          website: this.website, // honeypot
        },
      });

      this.unlocked = true;
      this.subject = "";
      this.message = "";
      this.website = ""; // keep empty
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
      this.error = I18n.t("js.anonymous_feedback.errors.missing_fields");
      return;
    }

    this.sending = true;
    try {
      await ajax(this.args.sendUrl, {
        type: "POST",
        data: {
          subject,
          message,
          website: this.website, // honeypot
        },
      });

      // One unlock = one send
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
      this.error = I18n.t(
        `js.anonymous_feedback.errors.${json.error_key}`,
        json.error_params
      );
    } else {
      this.error = I18n.t("js.anonymous_feedback.errors.generic");
    }
  }
}
