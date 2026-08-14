import RouteTemplate from "discourse/routing/route-template";
import AnonymousFeedbackForm from "../components/anonymous-feedback-form";

export default RouteTemplate(
  <template>
    <AnonymousFeedbackForm
      @title={{@controller.title}}
      @intro={{@controller.intro}}
      @unlockUrl="/anonymous-feedback/unlock"
      @sendUrl="/anonymous-feedback"
      @subjectPlaceholder={{@controller.subjectPlaceholder}}
      @messagePlaceholder={{@controller.messagePlaceholder}}
    />
  </template>
);
