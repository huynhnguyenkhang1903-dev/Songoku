let config = {
    scenarios: [],
    props: [],
    expressions: [],
    weapons: [],
    maxNPCs: 100,
    defaultNPCCount: 5
};

let npcCount = 0;
let isMenuVisible = false;
let currentTabIndex = 0;
const tabs = ['spawn', 'animations', 'props', 'weapons', 'expressions', 'vehicles', 'combat', 'manage'];

// Initialize UI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'toggleMenu') {
        toggleMenu(data.visible);
    } else if (data.type === 'initConfig') {
        config.scenarios = data.scenarios;
        config.props = data.props;
        config.expressions = data.expressions;
        config.weapons = data.weapons;
        config.weaponSkins = data.weaponSkins || {};
        config.maxNPCs = data.maxNPCs;
        config.defaultNPCCount = data.defaultNPCCount;
        
        populateSelects();
        document.getElementById('npcCountInput').value = config.defaultNPCCount;
    } else if (data.type === 'updateNPCCounts') {
        npcCount = data.total;
        document.getElementById('npcCount').textContent = npcCount;
        
        // Update group count labels in dropdown options
        const activeGroupSelect = document.getElementById('activeGroupSelect');
        const groups = ['group1', 'group2', 'group3', 'group4', 'group5'];
        
        for (let i = 0; i < activeGroupSelect.options.length; i++) {
            const opt = activeGroupSelect.options[i];
            if (opt.value === 'all') {
                opt.textContent = `Tất cả (${data.total})`;
            } else if (groups.includes(opt.value)) {
                const num = opt.value.replace('group', '');
                const count = data.groupCounts[opt.value] || 0;
                opt.textContent = `Nhóm ${num} (${count})`;
            }
        }
    }
});

function toggleMenu(visible) {
    const menu = document.getElementById('menu');
    const arrow = document.getElementById('menuArrow');
    isMenuVisible = visible;
    
    if (visible) {
        menu.classList.add('visible');
        arrow.style.display = 'none';
    } else {
        menu.classList.remove('visible');
        arrow.style.display = 'flex';
    }
}

// Arrow click handler
document.getElementById('menuArrow').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/toggleMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(resp => resp.json());
});

// TAB key handler to switch tabs
document.addEventListener('keydown', function(event) {
    if (event.key === 'Tab' && isMenuVisible) {
        event.preventDefault();
        currentTabIndex = (currentTabIndex + 1) % tabs.length;
        switchTab(tabs[currentTabIndex]);
    }
});

function populateSelects() {
    // Populate scenarios
    const scenarioSelect = document.getElementById('scenarioSelect');
    scenarioSelect.innerHTML = '';
    config.scenarios.forEach(scenario => {
        const option = document.createElement('option');
        option.value = scenario;
        option.textContent = scenario;
        scenarioSelect.appendChild(option);
    });
    
    // Populate props
    const propSelect = document.getElementById('propSelect');
    propSelect.innerHTML = '';
    config.props.forEach(prop => {
        const option = document.createElement('option');
        option.value = prop.model;
        option.textContent = prop.name;
        propSelect.appendChild(option);
    });
    
    // Populate expressions
    const expressionSelect = document.getElementById('expressionSelect');
    expressionSelect.innerHTML = '';
    config.expressions.forEach(expression => {
        const option = document.createElement('option');
        option.value = expression.mood;
        option.textContent = expression.name;
        expressionSelect.appendChild(option);
    });
    
    // Populate weapons (tab Weapons + combat A + combat B)
    const weaponSelect    = document.getElementById('weaponSelect');
    const combatWeaponA   = document.getElementById('combatWeaponASelect');
    const combatWeaponB   = document.getElementById('combatWeaponBSelect');
    weaponSelect.innerHTML = '';
    combatWeaponA.innerHTML = '';
    combatWeaponB.innerHTML = '';

    config.weapons.forEach(weapon => {
        const makeOpt = () => {
            const o = document.createElement('option');
            o.value = weapon;
            o.textContent = weapon.replace('WEAPON_', '');
            return o;
        };
        weaponSelect.appendChild(makeOpt());
        combatWeaponA.appendChild(makeOpt());
        combatWeaponB.appendChild(makeOpt());
    });
    
    updateWeaponSkins();
    updateCombatWeaponSkinsA();
    updateCombatWeaponSkinsB();
}

function switchTab(tabName) {
    // Update current tab index
    currentTabIndex = tabs.indexOf(tabName);
    
    // Hide all tabs
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected tab
    document.getElementById(tabName + '-tab').classList.add('active');
    
    // Add active class to corresponding button
    const buttons = document.querySelectorAll('.tab-btn');
    buttons.forEach(btn => {
        if (btn.textContent.toLowerCase().includes(tabName)) {
            btn.classList.add('active');
        }
    });
}

// Update active group in Lua to toggle markers
function updateActiveGroup() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/changeActiveGroup`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

// Spawn NPCs
function spawnNPCs() {
    const count = document.getElementById('npcCountInput').value;
    const direction = document.getElementById('spawnDirection').value;
    const relationship = document.getElementById('spawnRelationshipSelect').value;
    
    // Doc so nhom tu input, chuyen sang ten nhom group1..group20
    const groupNum = parseInt(document.getElementById('spawnGroupInput').value) || 1;
    const clampedNum = Math.max(1, Math.min(groupNum, 20));
    const group = 'group' + clampedNum;
    
    fetch(`https://${GetParentResourceName()}/spawnNPCs`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            count: count,
            direction: direction,
            group: group,
            relationship: relationship
        })
    });
}

// Apply emoji code
function applyEmojiCode() {
    const emojiCode = document.getElementById('emojiCodeInput').value;
    const group = document.getElementById('activeGroupSelect').value;
    if (emojiCode) {
        fetch(`https://${GetParentResourceName()}/applyEmojiCode`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                emojiCode: emojiCode,
                group: group
            })
        });
    }
}

// Apply scenario
function applyScenario() {
    const scenario = document.getElementById('scenarioSelect').value;
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/applyScenario`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            scenario: scenario,
            group: group
        })
    });
}

// Clear scenarios
function clearScenarios() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/clearScenarios`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

function updateWeaponSkins() {
    const weaponSelect = document.getElementById('weaponSelect');
    const skinSelect = document.getElementById('weaponSkinSelect');
    if (!weaponSelect || !skinSelect) return;
    
    const selectedWeapon = weaponSelect.value;
    
    // Clear current options
    skinSelect.innerHTML = '<option value="default">Mặc định</option>';
    
    if (config.weaponSkins && config.weaponSkins[selectedWeapon]) {
        const skins = config.weaponSkins[selectedWeapon];
        skins.forEach(skin => {
            const option = document.createElement('option');
            option.value = skin.component;
            option.textContent = skin.name;
            skinSelect.appendChild(option);
        });
    }
}

function updateCombatWeaponSkinsA() {
    const weaponSelect = document.getElementById('combatWeaponASelect');
    const skinSelect   = document.getElementById('combatWeaponSkinASelect');
    if (!weaponSelect || !skinSelect) return;
    const selectedWeapon = weaponSelect.value;
    skinSelect.innerHTML = '<option value="default">Mặc định</option>';
    if (config.weaponSkins && config.weaponSkins[selectedWeapon]) {
        config.weaponSkins[selectedWeapon].forEach(skin => {
            const option = document.createElement('option');
            option.value = skin.component;
            option.textContent = skin.name;
            skinSelect.appendChild(option);
        });
    }
}

function updateCombatWeaponSkinsB() {
    const weaponSelect = document.getElementById('combatWeaponBSelect');
    const skinSelect   = document.getElementById('combatWeaponSkinBSelect');
    if (!weaponSelect || !skinSelect) return;
    const selectedWeapon = weaponSelect.value;
    skinSelect.innerHTML = '<option value="default">Mặc định</option>';
    if (config.weaponSkins && config.weaponSkins[selectedWeapon]) {
        config.weaponSkins[selectedWeapon].forEach(skin => {
            const option = document.createElement('option');
            option.value = skin.component;
            option.textContent = skin.name;
            skinSelect.appendChild(option);
        });
    }
}

// Keep old updateCombatWeaponSkins as alias (phong bi loi neu con ref cu)
function updateCombatWeaponSkins() {
    updateCombatWeaponSkinsA();
    updateCombatWeaponSkinsB();
}

// Give weapon
function giveWeapon() {
    const weapon = document.getElementById('weaponSelect').value;
    const skin = document.getElementById('weaponSkinSelect').value;
    const group = document.getElementById('activeGroupSelect').value;
    
    fetch(`https://${GetParentResourceName()}/giveWeapon`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            weapon: weapon,
            skin: skin,
            group: group
        })
    });
}

// Remove weapons
function removeWeapons() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/removeWeapons`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

// Give prop
function giveProp() {
    const prop = document.getElementById('propSelect').value;
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/giveProp`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            prop: prop,
            group: group
        })
    });
}

// Remove props
function removeProps() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/removeProps`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

// Set expression
function setExpression() {
    const expression = document.getElementById('expressionSelect').value;
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/setExpression`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            expression: expression,
            group: group
        })
    });
}

// Delete all NPCs
function deleteAllNPCs() {
    const group = document.getElementById('activeGroupSelect').value;
    let confirmMsg = 'Bạn có chắc muốn xóa tất cả NPC?';
    if (group !== 'all') {
        const groupLabel = document.querySelector(`#activeGroupSelect option[value="${group}"]`).textContent;
        const cleanName = groupLabel.split(' (')[0];
        confirmMsg = `Bạn có chắc muốn xóa các NPC thuộc ${cleanName}?`;
    }
    if (confirm(confirmMsg)) {
        fetch(`https://${GetParentResourceName()}/deleteAllNPCs`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                group: group
            })
        });
    }
}

// Freeze NPCs - su dung dropdown rieng
function freezeNPCs(freeze) {
    const group = document.getElementById('freezeGroupSelect')
        ? document.getElementById('freezeGroupSelect').value
        : document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/freezeNPCs`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            freeze: freeze,
            group: group
        })
    });
}

// Set invincible - su dung activeGroupSelect (chung)
function setInvincible(invincible) {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/setInvincible`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            invincible: invincible,
            group: group
        })
    });
}

// Set invincible - su dung dropdown nhom rieng trong Manage
function setInvincibleGroup(invincible) {
    const group = document.getElementById('invincibleGroupSelect')
        ? document.getElementById('invincibleGroupSelect').value
        : document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/setInvincible`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            invincible: invincible,
            group: group
        })
    });
}

// Set health - su dung dropdown nhom rieng
function setHealth() {
    const health = document.getElementById('healthInput').value;
    const group = document.getElementById('healthGroupSelect')
        ? document.getElementById('healthGroupSelect').value
        : document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/setHealth`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            health: health,
            group: group
        })
    });
}

// Follow player
function followPlayer() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/followPlayer`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

// Stay
function stay() {
    const group = document.getElementById('activeGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/stay`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group
        })
    });
}

// Close menu
function closeMenu() {
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
}

// Keyboard handler for ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});

// Spawn Vehicles
function spawnVehicles() {
    const model = document.getElementById('vehicleModelInput').value.trim();
    const count = parseInt(document.getElementById('vehicleCountInput').value) || 1;
    const distance = parseFloat(document.getElementById('vehicleDistanceInput').value) || 5.0;
    const spawnNpc = document.getElementById('vehicleSpawnNPC').value === 'yes';
    const driveMode = document.getElementById('vehicleDriveMode').value;
    const group = document.getElementById('activeGroupSelect').value;

    if (!model) {
        alert('Vui lòng nhập tên model xe!');
        return;
    }

    const color1 = parseInt(document.getElementById('vehicleColor1').value) || 0;
    const color2 = parseInt(document.getElementById('vehicleColor2').value) || 0;

    fetch(`https://${GetParentResourceName()}/spawnVehicles`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            model: model,
            count: count,
            distance: distance,
            spawnNpc: spawnNpc,
            driveMode: driveMode,
            group: group,
            color1: color1,
            color2: color2
        })
    });
}

// Delete Vehicles
function deleteVehicles() {
    const group = document.getElementById('activeGroupSelect').value;
    let confirmMsg = 'Bạn có chắc muốn xóa tất cả xe đã spawn?';
    if (group !== 'all') {
        const groupLabel = document.querySelector(`#activeGroupSelect option[value="${group}"]`).textContent;
        const cleanName = groupLabel.split(' (')[0];
        confirmMsg = `Bạn có chắc muốn xóa các xe thuộc ${cleanName}?`;
    }
    if (confirm(confirmMsg)) {
        fetch(`https://${GetParentResourceName()}/deleteVehicles`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                group: group
            })
        });
    }
}

// Update Vehicle Driving Behavior
function updateVehicleBehavior() {
    const driveMode = document.getElementById('vehicleDriveMode').value;
    const group = document.getElementById('activeGroupSelect').value;

    fetch(`https://${GetParentResourceName()}/updateVehicleBehavior`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            driveMode: driveMode,
            group: group
        })
    });
}

// Helper: lay gia tri nhom combat (so hoac 'player')
function getCombatGroup(side) {
    const isPlayer = document.getElementById('combatGroup' + side + 'IsPlayer').checked;
    if (isPlayer) return 'player';
    const num = parseInt(document.getElementById('combatGroup' + side + 'Input').value) || 1;
    const clamped = Math.max(1, Math.min(num, 20));
    return 'group' + clamped;
}

// Toggle hien/an input so khi tick 'La Player'
function toggleCombatGroupA() {
    const isPlayer = document.getElementById('combatGroupAIsPlayer').checked;
    document.getElementById('combatGroupAInput').disabled = isPlayer;
    document.getElementById('combatGroupAInput').style.opacity = isPlayer ? '0.4' : '1';
}
function toggleCombatGroupB() {
    const isPlayer = document.getElementById('combatGroupBIsPlayer').checked;
    document.getElementById('combatGroupBInput').disabled = isPlayer;
    document.getElementById('combatGroupBInput').style.opacity = isPlayer ? '0.4' : '1';
}

// Start Fight - moi nhom co weapon/skin rieng
function startFight() {
    const groupA  = getCombatGroup('A');
    const groupB  = getCombatGroup('B');
    const weaponA = document.getElementById('combatWeaponASelect').value;
    const skinA   = document.getElementById('combatWeaponSkinASelect').value;
    const weaponB = document.getElementById('combatWeaponBSelect').value;
    const skinB   = document.getElementById('combatWeaponSkinBSelect').value;
    const behavior = document.getElementById('combatBehaviorSelect').value;

    if (groupA === groupB) {
        alert('Nhóm A và Nhóm B phải khác nhau!');
        return;
    }

    fetch(`https://${GetParentResourceName()}/startFight`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            groupA:  groupA,
            groupB:  groupB,
            weaponA: weaponA,
            skinA:   skinA,
            weaponB: weaponB,
            skinB:   skinB,
            behavior: behavior
        })
    });
}

// Make Peace
function makePeace() {
    const groupA = getCombatGroup('A');
    const groupB = getCombatGroup('B');

    fetch(`https://${GetParentResourceName()}/makePeace`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            groupA: groupA,
            groupB: groupB
        })
    });
}

// Follow Player Group (với nhóm và tốc độ riêng)
function followPlayerGroup() {
    const group = document.getElementById('followGroupSelect').value;
    const speed = document.getElementById('followSpeedSelect').value;
    fetch(`https://${GetParentResourceName()}/followPlayerGroup`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group,
            speed: parseFloat(speed)
        })
    });
}

// Set Movement Clip (Dáng đi) cho nhóm
function setMovementClip() {
    const group = document.getElementById('movementGroupSelect').value;
    const clip = document.getElementById('movementClipSelect').value;
    fetch(`https://${GetParentResourceName()}/setMovementClip`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group,
            clip: clip
        })
    });
}

// Reset Movement Clip về mặc định
function resetMovementClip() {
    const group = document.getElementById('movementGroupSelect').value;
    fetch(`https://${GetParentResourceName()}/setMovementClip`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            group: group,
            clip: 'reset'
        })
    });
}

// Helper: lay gia tri nhom couple (so hoac 'player')
function getCoupleGroup(side) {
    const isPlayer = document.getElementById('coupleGroup' + side + 'IsPlayer').checked;
    if (isPlayer) return 'player';
    const num = parseInt(document.getElementById('coupleGroup' + side + 'Input').value) || 1;
    const clamped = Math.max(1, Math.min(num, 20));
    return 'group' + clamped;
}

// Toggle hien/an input so khi tick 'La Player'
function toggleCoupleGroupA() {
    const isPlayer = document.getElementById('coupleGroupAIsPlayer').checked;
    document.getElementById('coupleGroupAInput').disabled = isPlayer;
    document.getElementById('coupleGroupAInput').style.opacity = isPlayer ? '0.4' : '1';
}
function toggleCoupleGroupB() {
    const isPlayer = document.getElementById('coupleGroupBIsPlayer').checked;
    document.getElementById('coupleGroupBInput').disabled = isPlayer;
    document.getElementById('coupleGroupBInput').style.opacity = isPlayer ? '0.4' : '1';
}

function startCoupleAnim() {
    const groupA = getCoupleGroup('A');
    const groupB = getCoupleGroup('B');
    const anim = document.getElementById('coupleAnimSelect').value;

    if (groupA === groupB) {
        alert('Người thực hiện và Người nhận phải khác nhau!');
        return;
    }

    fetch(`https://${GetParentResourceName()}/startCoupleAnim`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            groupA: groupA,
            groupB: groupB,
            anim: anim
        })
    });
}

function stopCoupleAnim() {
    const groupA = getCoupleGroup('A');
    const groupB = getCoupleGroup('B');

    fetch(`https://${GetParentResourceName()}/stopCoupleAnim`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            groupA: groupA,
            groupB: groupB
        })
    });
}
