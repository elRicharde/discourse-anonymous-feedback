import RouteTemplate from "discourse/routing/route-template";
import AnonymousFeedbackForm from "../components/anonymous-feedback-form";

export default RouteTemplate(
  <template>
    <AnonymousFeedbackForm
      @title={{@controller.title}}
      @intro={{@controller.intro}}
      @unlockUrl="/white-board/unlock"
      @sendUrl="/white-board"
      @subjectPlaceholder={{@controller.subjectPlaceholder}}
      @messagePlaceholder={{@controller.messagePlaceholder}}
    />
  </template>
);
