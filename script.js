// Controller navigation support
let selectedIndex = null;
let isInSubmenu = false;
window.lastMainMenuMods = []; // Store the last main menu mod list

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    if (event.data.type === 'setMods') {
        document.getElementById('menu').style.display = 'block'; // Show menu
        buildMenu(event.data.mods);
        selectedIndex = 0; // Start with first item selected
        isInSubmenu = false;
        updateSelection();
    }
    if (event.data.type === 'setModOptions') {
        // If Neons, try to keep selection
        const keepSelected = event.data.modName === 'Neons';
        buildSubMenu(event.data.modName, event.data.options, keepSelected);
        selectedIndex = 0; // Start with first item selected (Back button)
        isInSubmenu = true;
        updateSelection();
    }
    if (event.data.type === 'closeMenu') {
        closeMenu();
    }
    if (event.data.type === 'navigate') {
        handleNavigation(event.data.direction);
    }
});

function handleNavigation(direction) {
    const ul = document.querySelector('#menu ul');
    const items = ul.querySelectorAll('li');
    if (!items.length) return;
    
    let currentSelectedIndex = selectedIndex === null ? 0 : selectedIndex;

    if (direction === 'up') {
        currentSelectedIndex = (currentSelectedIndex - 1 + items.length) % items.length;
    } else if (direction === 'down') {
        currentSelectedIndex = (currentSelectedIndex + 1) % items.length;
    } else if (direction === 'accept') {
        if (selectedIndex !== null && items[selectedIndex]) {
            items[selectedIndex].click();
        }
        return; // Prevent selection update after click
    } else if (direction === 'back') {
        if (isInSubmenu) {
            // Find and click the 'Back' button programmatically
            const backButton = ul.querySelector('.back');
            if (backButton) {
                backButton.click();
            }
        } else {
            closeMenu();
        }
        return; // Prevent selection update
    }
    
    selectedIndex = currentSelectedIndex;
    updateSelection();
}


function updateSelection() {
    const ul = document.querySelector('#menu ul');
    const items = ul.querySelectorAll('li');
    items.forEach((li, idx) => {
        if (selectedIndex !== null && idx === selectedIndex) {
            li.classList.add('selected');
            li.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        } else {
            li.classList.remove('selected');
        }
    });
}

function buildMenu(modList) {
    const ul = document.querySelector('#menu ul');
    ul.innerHTML = '';
    ul.classList.remove('submenu');
    window.lastMainMenuMods = modList; // Save the dynamic list
    isInSubmenu = false;
    
    // Build menu ONLY from the dynamic list sent by Lua
    modList.forEach((mod, index) => {
        const li = document.createElement('li');
        li.textContent = mod;
        li.dataset.modName = mod;
        
        li.addEventListener('click', function(e) {
            selectedIndex = index;
            updateSelection();
            fetch(`https://${GetParentResourceName()}/getModOptions`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ mod: this.dataset.modName })
            });
            e.stopPropagation();
        });
        
        ul.appendChild(li);
    });
    
    selectedIndex = 0;
    updateSelection();
}

function buildSubMenu(modName, options, keepSelectedIndex) {
    const ul = document.querySelector('#menu ul');
    ul.innerHTML = '';
    ul.classList.add('submenu');
    isInSubmenu = true;

    // Create a Back button
    const backLi = document.createElement('li');
    backLi.textContent = '⬅ Back';
    backLi.className = 'back';
    backLi.addEventListener('click', function(e) {
        buildMenu(window.lastMainMenuMods);
        selectedIndex = 0;
        isInSubmenu = false;
        updateSelection();
        e.stopPropagation();
    });
    ul.appendChild(backLi);

    // Always build submenu from latest options (no caching)
    options.forEach((opt, index) => {
        const li = document.createElement('li');
        if ((modName === 'Neons' && opt.index === 'enable_all') || (modName === 'Max Upgrade' && opt.index === 'max_upgrade')) {
            li.innerHTML = `<span class="checkbox${opt.checked ? ' checked' : ''}"></span> <span>${opt.name}</span>`;
        } else {
            li.textContent = opt.name;
        }
        li.dataset.modName = modName;
        li.dataset.optionIndex = opt.index;
        li.addEventListener('click', function(e) {
            // Save the intended selection index for after refresh
            if (modName === 'Neons') {
                window.lastNeonSelectedIndex = index + 1; // +1 for back button
                selectedIndex = window.lastNeonSelectedIndex;
            } else if (modName === 'Max Upgrade') {
                // Don't update selection on toggle actions
            } else if (modName === 'Headlights') {
                // For headlights, keep track of selection for colors
                window.lastHeadlightSelectedIndex = index + 1;
                selectedIndex = window.lastHeadlightSelectedIndex;
            }
            updateSelection();
            fetch(`https://${GetParentResourceName()}/selectModOption`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ 
                    mod: this.dataset.modName, 
                    optionIndex: this.dataset.optionIndex 
                })
            });
            e.stopPropagation();
        });
        ul.appendChild(li);
    });

    // Restore selection if requested (for Neons submenu)
    if (modName === 'Neons' && typeof window.lastNeonSelectedIndex === 'number' && keepSelectedIndex) {
        selectedIndex = window.lastNeonSelectedIndex;
    } else {
        selectedIndex = 0;
    }
    updateSelection();
}

function closeMenu() {
    document.getElementById('menu').style.display = 'none';
    const ul = document.querySelector('#menu ul');
    ul.innerHTML = '';
    ul.classList.remove('submenu');
    selectedIndex = null;
    isInSubmenu = false;
    
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}


// --- All your event listeners for input (keyboard, mouse, etc.) are fine ---
// --- They can remain as they are. No changes needed below this line. ---
document.addEventListener('keydown',function(e){if(document.getElementById('menu').style.display!=='block')return;if(e.code==='ArrowUp'){handleNavigation('up');e.preventDefault();}else if(e.code==='ArrowDown'){handleNavigation('down');e.preventDefault();}else if(e.code==='Enter'||e.code==='NumpadEnter'){handleNavigation('accept');e.preventDefault();}else if(e.code==='Escape'){handleNavigation('back');e.preventDefault();}});
let lastWheelTime=0;document.addEventListener('wheel',function(e){const now=Date.now();if(now-lastWheelTime<100)return;lastWheelTime=now;if(e.deltaY>0){handleNavigation('down');}else{handleNavigation('up');}e.preventDefault();},{passive:false});
document.addEventListener('click',function(e){const ul=document.querySelector('#menu ul');if(!ul.querySelectorAll('li').length)return;const clickedItem=e.target.closest('li');if(clickedItem&&ul.contains(clickedItem)){const index=Array.from(ul.querySelectorAll('li')).indexOf(clickedItem);if(index!==-1){selectedIndex=index;updateSelection();if(clickedItem.onclick){clickedItem.onclick(e);}}e.preventDefault();e.stopPropagation();}});
document.addEventListener('mousedown',function(e){const ul=document.querySelector('#menu ul');if(!ul.querySelectorAll('li').length)return;const clickedItem=e.target.closest('li');if(clickedItem&&ul.contains(clickedItem)){const index=Array.from(ul.querySelectorAll('li')).indexOf(clickedItem);if(index!==-1){selectedIndex=index;updateSelection();}e.preventDefault();e.stopPropagation();}});
document.addEventListener('selectstart',function(e){const menu=document.getElementById('menu');if(menu&&menu.contains(e.target)){e.preventDefault();}});