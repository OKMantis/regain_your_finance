import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detail", "chevron"]

  toggle() {
    const open = !this.detailTarget.classList.contains("hidden")
    this.detailTarget.classList.toggle("hidden", open)
    this.chevronTarget.style.transform = open ? "" : "rotate(180deg)"
  }
}
