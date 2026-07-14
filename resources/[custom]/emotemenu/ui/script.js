let allEmotes = [];
let currentCategory = "all";
let searchQuery = "";
let activeEmoteId = null;

const app = document.getElementById("app");
const emoteGrid = document.getElementById("emote-grid");
const searchInput = document.getElementById("search-input");
const clearSearchBtn = document.getElementById("clear-search");
const categoryButtons = document.querySelectorAll(".category-btn");
const stopEmoteBtnSidebar = document.getElementById("stop-emote-sidebar");
const activeBadge = document.getElementById("active-emote-badge");
const activeName = document.getElementById("active-emote-name");

// UI Toggle Event Listener
window.addEventListener("message", function(event) {
    const data = event.data;
    if (data.action === "open") {
        if (data.emotes) {
            allEmotes = data.emotes;
        }
        openMenu();
    } else if (data.action === "close") {
        closeMenu();
    }
});

// Close NUI by pressing Escape or F5
window.addEventListener("keydown", function(event) {
    if (event.key === "Escape" || event.key === "F5") {
        closeMenuRequest();
    }
});

// Category Filter Event Listeners
categoryButtons.forEach(button => {
    button.addEventListener("click", () => {
        categoryButtons.forEach(btn => btn.classList.remove("active"));
        button.classList.add("active");
        currentCategory = button.getAttribute("data-category");
        renderEmotes();
    });
});

// Search Input Listener
searchInput.addEventListener("input", (e) => {
    searchQuery = e.target.value.toLowerCase().trim();
    if (searchQuery.length > 0) {
        clearSearchBtn.classList.remove("hidden");
    } else {
        clearSearchBtn.classList.add("hidden");
    }
    renderEmotes();
});

// Clear Search Input
clearSearchBtn.addEventListener("click", () => {
    searchInput.value = "";
    searchQuery = "";
    clearSearchBtn.classList.add("hidden");
    searchInput.focus();
    renderEmotes();
});

// Stop Emote Button Click
stopEmoteBtnSidebar.addEventListener("click", () => {
    stopEmote();
});

// Request Close to Client
function closeMenuRequest() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(resp => {
        closeMenu();
    }).catch(err => {
        closeMenu(); // fallback
    });
}

function openMenu() {
    app.classList.remove("hidden");
    searchInput.focus();
    renderEmotes();
}

function closeMenu() {
    app.classList.add("hidden");
}

// Play Emote Callback
function playEmote(emote) {
    fetch(`https://${GetParentResourceName()}/playEmote`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify(emote)
    }).then(resp => resp.json()).then(status => {
        if (status === "ok") {
            activeEmoteId = emote.id;
            updateActiveBadge(emote.label);
            renderEmotes(); // refresh active highlights
            closeMenuRequest();
        }
    });
}

// Stop Emote Callback
function stopEmote() {
    fetch(`https://${GetParentResourceName()}/clearEmote`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8"
        },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(status => {
        activeEmoteId = null;
        activeBadge.classList.add("hidden");
        renderEmotes(); // refresh active highlights
    });
}

// Update Active Badge
function updateActiveBadge(label) {
    activeName.textContent = label;
    activeBadge.classList.remove("hidden");
}

// Get Icon class for category
function getCategoryIcon(category) {
    switch (category) {
        case "actions":
            return "fa-hands-clapping";
        case "postures":
            return "fa-couch";
        case "dances":
            return "fa-music";
        case "scenarios":
            return "fa-mug-hot";
        case "combat_atk":
            return "fa-hand-fist";
        case "combat_def":
            return "fa-user-injured";
        case "combat_choreo":
            return "fa-user-ninja";
        default:
            return "fa-person";
    }
}

// Get Category Label in Vietnamese
function getCategoryLabel(category) {
    switch (category) {
        case "actions": return "Hành động";
        case "postures": return "Tư thế";
        case "dances": return "Điệu nhảy";
        case "scenarios": return "Vật phẩm";
        case "combat_atk": return "Tấn công";
        case "combat_def": return "Bị đòn / Đỡ";
        case "combat_choreo": return "Đấu võ tự động";
        default: return "";
    }
}

// Render Emotes Grid
function renderEmotes() {
    emoteGrid.innerHTML = "";

    // Filter emotes
    const filteredEmotes = allEmotes.filter(emote => {
        const matchesCategory = (currentCategory === "all" || emote.category === currentCategory);
        const matchesSearch = (emote.label.toLowerCase().includes(searchQuery) || emote.id.toLowerCase().includes(searchQuery));
        return matchesCategory && matchesSearch;
    });

    if (filteredEmotes.length === 0) {
        emoteGrid.innerHTML = `
            <div style="grid-column: 1 / -1; color: var(--text-muted); text-align: center; padding: 40px 0;">
                <i class="fa-solid fa-face-frown" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                Không tìm thấy emote phù hợp
            </div>
        `;
        return;
    }

    filteredEmotes.forEach(emote => {
        const card = document.createElement("div");
        card.className = `emote-card ${activeEmoteId === emote.id ? 'active' : ''}`;
        
        const categoryIcon = getCategoryIcon(emote.category);
        const categoryLabel = getCategoryLabel(emote.category);

        card.innerHTML = `
            <div class="emote-icon-wrapper">
                <i class="fa-solid ${categoryIcon} emote-icon"></i>
            </div>
            <div class="emote-name">${emote.label}</div>
            <div class="emote-category-tag">${categoryLabel}</div>
        `;

        card.addEventListener("click", () => {
            playEmote(emote);
        });

        emoteGrid.appendChild(card);
    });
}
