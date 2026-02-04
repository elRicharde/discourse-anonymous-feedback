import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { action } from "@ember/object";

export default class AnonymousFeedbackController extends Controller {
  @tracked doorCode = "";
  @tracked subject = "";
  @tracked message = "";
  @tracked unlocked = false;
  @tracked error = null;
  @tracked sending = false;
  @tracked sent = false;

  @action
  async unlock() {
    this.error = null;
    this.sent = false;

    try {
      await ajax("/anonymous-feedback/unlock.json", {
        type: "POST",
        data: { door_code: this.doorCode }
      });
      this.unlocked = true;
      this.doorCode = "";
    } catch (e) {
      this.unlocked = false;
      this.error = e?.jqXHR?.responseJSON?.error || "Fehler";
    }
  }

  @action
  async send() {
    this.error = null;
    this.sent = false;

    if (!this.subject?.trim() || !this.message?.trim()) {
      this.error = "Bitte Betreff und Nachricht ausfüllen.";
      return;
    }

    this.sending = true;
    try {
      await ajax("/anonymous-feedback.json", {
        type: "POST",
        data: {
          subject: this.subject,
          message: this.message
        }
      });

      this.sent = true;
      this.unlocked = false;
      this.subject = "";
      this.message = "";
    } catch (e) {
      this.error = e?.jqXHR?.responseJSON?.error || "Fehler";
    } finally {
      this.sending = false;
    }
  }
}
