import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "editForm", "entries", "chevron"]

  toggleEntries() {
    const open = this.entriesTarget.classList.contains("hidden")
    this.entriesTarget.classList.toggle("hidden", !open)
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = open ? "rotate(180deg)" : ""
    }
  }

  startEdit() {
    this.headerTarget.classList.add("hidden")
    this.editFormTarget.classList.remove("hidden")
  }

  cancelEdit() {
    this.editFormTarget.classList.add("hidden")
    this.headerTarget.classList.remove("hidden")
  }
}
