const COMPANY_WHATSAPP = "27601234567";

const menuButton = document.querySelector(".menu-toggle");
const navigation = document.querySelector("#site-nav");
if (menuButton && navigation) {
  menuButton.addEventListener("click", () => {
    const open = navigation.classList.toggle("open");
    menuButton.setAttribute("aria-expanded", String(open));
  });
  navigation.querySelectorAll("a").forEach(link => link.addEventListener("click", () => {
    navigation.classList.remove("open");
    menuButton.setAttribute("aria-expanded", "false");
  }));
}

// Keep the marketplace discoverable on the original marketing pages.
if (navigation && !navigation.querySelector('a[href="marketplace.html"]')) {
  const quoteLink = navigation.querySelector('a[href="quote.html"]');
  const marketplaceLink = document.createElement('a');
  marketplaceLink.href = 'marketplace.html';
  marketplaceLink.textContent = 'Marketplace';
  navigation.insertBefore(marketplaceLink, quoteLink || null);
}

document.querySelectorAll("[data-year]").forEach(node => node.textContent = new Date().getFullYear());

const money = value => new Intl.NumberFormat("en-ZA", {
  style: "currency", currency: "ZAR", maximumFractionDigits: 0
}).format(value);

const quoteForm = document.querySelector("#quote-form");
if (quoteForm) {
  const services = [
    {id:"addition", name:"New build / addition", unit:8500, min:45000, note:"per m²"},
    {id:"kitchen", name:"Kitchen renovation", unit:6200, min:65000, note:"per m²"},
    {id:"bathroom", name:"Bathroom renovation", unit:7800, min:48000, note:"per m²"},
    {id:"painting", name:"Painting & plastering", unit:420, min:8500, note:"per m²"},
    {id:"roofing", name:"Roofing & waterproofing", unit:1250, min:12000, note:"per m²"},
    {id:"flooring", name:"Flooring & tiling", unit:950, min:8500, note:"per m²"},
    {id:"paving", name:"Paving", unit:720, min:7500, note:"per m²"},
    {id:"other", name:"Other / mixed work", unit:1500, min:15000, note:"allowance per m²"}
  ];
  const options = document.querySelector("#project-options");
  services.forEach(service => {
    const label = document.createElement("label");
    label.className = "project-option";
    label.innerHTML = `<input type="checkbox" value="${service.id}"><span><b>${service.name}</b><small>From ${money(service.min)} · ${service.note}</small></span>`;
    options.append(label);
  });
  const area = document.querySelector("#area");
  const finish = document.querySelector("#finish");
  const timing = document.querySelector("#timing");
  const estimate = document.querySelector("#estimate");
  const count = document.querySelector("#service-count");
  const note = document.querySelector("#estimate-note");
  const ready = document.querySelector("#quote-ready");
  const button = document.querySelector("#whatsapp-button");
  const selected = () => [...options.querySelectorAll("input:checked")].map(input => services.find(service => service.id === input.value));
  const calculate = () => {
    const chosen = selected();
    const size = Math.max(1, Number(area.value) || 1);
    const multiplier = Number(finish.value) * Number(timing.value);
    const base = chosen.reduce((sum, service) => sum + Math.max(service.min, service.unit * size), 0);
    const low = Math.round(base * multiplier / 500) * 500;
    const high = Math.round(low * 1.18 / 500) * 500;
    estimate.textContent = chosen.length ? `${money(low)} – ${money(high)}` : "R0 – R0";
    count.textContent = chosen.length;
    document.querySelector("#finish-label").textContent = finish.options[finish.selectedIndex].text.split(" — ")[0];
    note.textContent = chosen.length ? `Based on approximately ${size} m². Final pricing follows a site visit.` : "Select at least one service to calculate.";
    button.disabled = !(chosen.length && ready.checked);
    return {chosen, size, low, high};
  };
  quoteForm.addEventListener("input", calculate);
  quoteForm.addEventListener("change", calculate);
  quoteForm.addEventListener("submit", event => {
    event.preventDefault();
    const quote = calculate();
    const name = document.querySelector("#client-name").value.trim() || "Not provided";
    const phone = document.querySelector("#client-phone").value.trim() || "Not provided";
    const location = document.querySelector("#location").value.trim() || "Not provided";
    const details = document.querySelector("#notes").value.trim() || "None added";
    const finishLabel = finish.options[finish.selectedIndex].text;
    const timingLabel = timing.options[timing.selectedIndex].text;
    const message = `Hello SolidForm Construction 👋\n\nI used your online quote builder and would like to discuss my project.\n\n*CLIENT DETAILS*\nName: ${name}\nContact: ${phone}\nLocation: ${location}\n\n*PROJECT BRIEF*\nServices: ${quote.chosen.map(service => service.name).join(", ")}\nApprox. size: ${quote.size} m²\nFinish: ${finishLabel}\nTiming: ${timingLabel}\nNotes: ${details}\n\n*INDICATIVE ESTIMATE*\n${money(quote.low)} – ${money(quote.high)} (VAT excluded)\n\nI understand this is an initial estimate and that a site assessment is required for a final quotation. Please contact me to arrange the next step.`;
    localStorage.setItem("solidform_quote_draft", JSON.stringify({
      services: quote.chosen.map(service => service.name), area: quote.size,
      estimateMin: quote.low, estimateMax: quote.high, location, details,
      finish: finishLabel, timing: timingLabel, savedAt: new Date().toISOString()
    }));
    window.open(`https://wa.me/${COMPANY_WHATSAPP}?text=${encodeURIComponent(message)}`, "_blank", "noopener,noreferrer");
  });
  calculate();
}

const contactForm = document.querySelector("#contact-form");
if (contactForm) {
  contactForm.addEventListener("submit", event => {
    event.preventDefault();
    const data = new FormData(contactForm);
    const message = `Hello SolidForm Construction 👋\n\nI would like to discuss a project.\n\nName: ${data.get("name") || "Not provided"}\nPhone: ${data.get("phone") || "Not provided"}\nPreferred contact time: ${data.get("time") || "Any time"}\nProject location: ${data.get("location") || "Not provided"}\nProject details: ${data.get("message") || "Not provided"}`;
    window.open(`https://wa.me/${COMPANY_WHATSAPP}?text=${encodeURIComponent(message)}`, "_blank", "noopener,noreferrer");
  });
}
