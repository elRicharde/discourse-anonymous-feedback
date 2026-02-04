import { ajax } from "discourse/lib/ajax";

function showError(msg) {
  const el = document.getElementById("af_error");
  if (el) {
    el.innerText = msg;
    el.style.display = "block";
  }
}

function unlock() {
  const input = document.getElementById("af_door_code");
  if (!input) {
    console.error("door code input not found");
    return;
  }

  ajax("/anonymous-feedback/unlock", {
    type: "POST",
    data: {
      door_code: input.value
    }
  })
    .then(() => {
      window.location.reload();
    })
    .catch((e) => {
      showError(e?.jqXHR?.responseJSON?.error || "Fehler");
    });
}

document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("af_unlock_btn");
  if (!btn) {
    console.warn("unlock button not found");
    return;
  }

  btn.addEventListener("click", unlock);
});
