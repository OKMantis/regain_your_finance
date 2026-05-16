import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "amountInput", "centsInput"]
  static values = { itemId: Number }

  connect() {
    this.displayTarget.addEventListener("click", () => this.open())
  }

  open() {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.amountInputTarget.focus()
  }

  cancel() {
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }

  convertToCents() {
    const euros = parseFloat(this.amountInputTarget.value) || 0
    this.centsInputTarget.value = Math.round(euros * 100)
  }
}
