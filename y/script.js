// Set current date
document.getElementById('currentDate').textContent = new Date().toLocaleDateString('en-US', {
    weekday: 'long', month: 'long', day: 'numeric'
})

// Tab switching
function showTab(tabName) {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'))
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'))
    document.getElementById(tabName).classList.add('active')
    event.target.classList.add('active')
}

// Sleep calculator
let sleepLog = []
function calculateSleep() {
    const bed = document.getElementById('bedtime').value
    const wake = document.getElementById('waketime').value
    if (!bed || !wake) return

    const bedDate = new Date(`2000-01-01T${bed}`)
    let wakeDate = new Date(`2000-01-01T${wake}`)
    if (wakeDate < bedDate) wakeDate.setDate(wakeDate.getDate() + 1)

    const diff = (wakeDate - bedDate) / 3600000
    const hours = Math.floor(diff)
    const minutes = Math.round((diff - hours) * 60)

    const quality = diff >= 8 ? 'Great' : diff >= 7 ? 'Good' : diff >= 6 ? 'Okay' : 'Poor'
    const result = `${hours}h ${minutes}m — ${quality} sleep`

    const el = document.getElementById('sleepResult')
    el.textContent = result
    el.classList.add('show')

    sleepLog.unshift({ time: new Date().toLocaleTimeString(), result })
    updateSleepHistory()
    localStorage.setItem('sleepHours', diff.toFixed(1))
}

function updateSleepHistory() {
    const el = document.getElementById('sleepHistory')
    el.innerHTML = sleepLog.slice(0, 5).map(s =>
        `<div class="history-item">${s.time} — ${s.result}</div>`
    ).join('')
}

// Gym tracker
let gymLog = []
function logWorkout() {
    const type = document.getElementById('workoutType').value
    const duration = document.getElementById('workoutDuration').value
    const notes = document.getElementById('workoutNotes').value

    if (!duration) return

    const entry = { type, duration, notes, time: new Date().toLocaleTimeString() }
    gymLog.unshift(entry)
    updateGymHistory()
    localStorage.setItem('workoutLogged', 'yes')
    localStorage.setItem('workoutType', type)
}

function updateGymHistory() {
    const el = document.getElementById('gymHistory')
    el.innerHTML = gymLog.slice(0, 5).map(g =>
        `<div class="history-item">${g.time} — ${g.type} (${g.duration} min) ${g.notes ? '· ' + g.notes : ''}</div>`
    ).join('')
}

// Habits tracker
function logHabits() {
    const checkboxes = document.querySelectorAll('.habit-item input[type="checkbox"]')
    let completed = 0
    checkboxes.forEach(c => { if (c.checked) completed++ })
    const total = checkboxes.length
    const pct = Math.round((completed / total) * 100)

    const el = document.getElementById('habitResult')
    el.textContent = `${completed}/${total} habits completed (${pct}%)`
    el.classList.add('show')
    localStorage.setItem('habitsCompleted', completed)
    localStorage.setItem('habitsTotal', total)
}

// Summary
function generateSummary() {
    const sleep = localStorage.getItem('sleepHours')
    const workout = localStorage.getItem('workoutLogged')
    const workoutType = localStorage.getItem('workoutType')
    const habits = localStorage.getItem('habitsCompleted')
    const total = localStorage.getItem('habitsTotal')

    document.getElementById('sumSleep').textContent = sleep ? `${sleep}h` : '--'
    document.getElementById('sumWorkout').textContent = workout ? workoutType : 'Rest'
    document.getElementById('sumHabits').textContent = habits ? `${habits}/${total}` : '--'

    let score = 0
    if (sleep >= 7) score += 34
    if (workout) score += 33
    if (habits && total) score += Math.round((habits / total) * 33)
    document.getElementById('sumScore').textContent = score ? `${score}%` : '--'
}

generateSummary()
