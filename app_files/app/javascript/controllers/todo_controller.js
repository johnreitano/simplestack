import { Controller } from "stimulus";

export default class extends Controller {
  connect() {}
}

$(document).on("turbo:load", function () {
  // NOTE: put code here that you want to get initialized on page load
});
