import AnonymousFeedbackForm from "../components/anonymous-feedback-form";

<template>
  <AnonymousFeedbackForm
    @title={{this.title}}
    @intro={{this.intro}}
    @unlockUrl="/anonymous-feedback/unlock"
    @sendUrl="/anonymous-feedback"
    @subjectPlaceholder={{this.subjectPlaceholder}}
    @messagePlaceholder={{this.messagePlaceholder}}
  />
</template>
