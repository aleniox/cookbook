import tkinter as tk
from tkinter import ttk

# --- Data (copied from your notebook) ---
onecost = [
  {"name":"tusk_champion","cost":1,"races":["beast"],"classes":["war"]},
  {"name":"otter_hunter","cost":1,"races":["beast"],"classes":["hunter"]},
  {"name":"unicorn","cost":1,"races":["beast","halforc"],"classes":["druid"]},
  {"name":"doctor","cost":1,"races":["glacier"],"classes":["warlock"]},
  {"name":"defector","cost":1,"races":["glacier"],"classes":["shaman"]},
  {"name":"fortune_teller","cost":1,"races":["glacier"],"classes":["priest"]},
  {"name":"the_source","cost":1,"races":["human"],"classes":["mage"]},
  {"name":"soul_breaker","cost":1,"races":["goblin","ancestor"],"classes":["hunter"]},
  {"name":"sky_breaker","cost":1,"races":["goblin"],"classes":["mech"]},
  {"name":"heaven_bomber","cost":1,"races":["goblin"],"classes":["mech"]},
  {"name":"grimtouch","cost":1,"races":["demon"],"classes":["wizard"]},
  {"name":"shining_archer","cost":1,"races":["feathered"],"classes":["hunter"]},
  {"name":"carnation_elf","cost":1,"races":["feathered"],"classes":["wizard"]},
  {"name":"ogre_mage","cost":1,"races":["kira"],"classes":["mage"]},
  {"name":"stone_spirit","cost":1,"races":["spirit"],"classes":["war"]},
  {"name":"god_of_war","cost":1,"races":["divinity"],"classes":["war"]},
  {"name":"daily_guard","cost":1,"races":["rhino"],"classes":["assassin"]},
  {"name":"nameless_horror","cost":1,"races":["dark_demon"],"classes":["warlock"]},
  {"name":"penitent_bishop","cost":1,"races":["ancestor","demon"],"classes":["priest"]}
]

twocost = [
  {"name":"swordman","cost":2,"races":["red"],"classes":["war"]},
  {"name":"lightblade_knight","cost":2,"races":["feathered"],"classes":["knight"]},
  {"name":"wind_ranger","cost":2,"races":["feathered"],"classes":["hunter"]},
  {"name":"dominator","cost":2,"races":["greater"],"classes":["assassin"]},
  {"name":"whisper_seer","cost":2,"races":["feathered"],"classes":["druid"]},
  {"name":"abyssalcrawler","cost":2,"races":["marine"],"classes":["assassin"]},
  {"name":"shiningdragon","cost":2,"races":["feathered","dragon"],"classes":["mage"]},
  {"name":"heaven_brew","cost":2,"races":["pandaman"],"classes":["martialist"]},
  {"name":"frost_knight","cost":2,"races":["glacier"],"classes":["knight"]},
  {"name":"sandbound_aegis","cost":2,"races":["halforc"],"classes":["war"]},
  {"name":"hell_knight","cost":2,"races":["demon"],"classes":["knight"]},
#   {"name":"underworld_executor","cost":2,"races":["egersis"],"classes":["hunter"]},
  {"name":"dwarf_sniper","cost":2,"races":["dwarf"],"classes":["hunter"]},
  {"name":"flame_wizard","cost":2,"races":["human"],"classes":["mage"]},
#   {"name":"wrath_image","cost":2,"races":["egersis"],"classes":["witcher"]},
  {"name":"skull_hunter","cost":2,"races":["red"],"classes":["hunter"]},
  {"name":"water_spirit","cost":2,"races":["spirit"],"classes":["assassin"]},
  {"name":"goddess_of_light","cost":2,"races":["divinity"],"classes":["priest"]},
  {"name":"ripper","cost":2,"races":["goblin"],"classes":["mech"]},
  {"name":"dark_lord","cost":2,"races":["ancestor"],"classes":["warlock"]},
  {"name":"deep_dive","cost":2,"races":["marine"],"classes":["wizard"]},
  {"name":"lava_shaman","cost":2,"races":["red"],"classes":["shaman"]}
]

threescost = [
  {"name":"gem_artisan","cost":3,"races":["civet"],"classes":["mech"]},
  {"name":"rhino_priest","cost":3,"races":["rhino"],"classes":["shaman"]},
  {"name":"wind_martialist","cost":3,"races":["feathered"],"classes":["martialist"]},
  {"name":"grand_herald","cost":3,"races":["divinity"],"classes":["wizard"]},
  {"name":"mist_demon_lord","cost":3,"races":["dark_demon"],"classes":["assassin"]},
  {"name":"venom","cost":3,"races":["dragon"],"classes":["assassin"]},
  {"name":"lord_of_sand","cost":3,"races":["insectoid"],"classes":["assassin"]},
  {"name":"war_goddess","cost":3,"races":["ancestor"],"classes":["knight"]},
  {"name":"thunder_spirit","cost":3,"races":["spirit"],"classes":["mage"]},
  {"name":"shadow_devil","cost":3,"races":["demon"],"classes":["warlock"]},
  {"name":"fallen_witcher","cost":3,"races":["demon"],"classes":["witcher"]},
  {"name":"avenge_knight","cost":3,"races":["human"],"classes":["knight"]},
  {"name":"abyssal_guard","cost":3,"races":["marine"],"classes":["war"]},
  {"name":"poisonous_worm","cost":3,"races":["insectoid","beast"],"classes":["warlock"]},
  {"name":"werewolf","cost":3,"races":["human","beast"],"classes":["war"]},
  {"name":"sacred_lancer","cost":3,"races":["glacier"],"classes":["war"]},
  {"name":"dark_spirit","cost":3,"races":["spirit"],"classes":["warlock"]},
  {"name":"warpwood_sage","cost":3,"races":["feathered"],"classes":["druid"]}
]

fourescost = [
  {"name":"taboo_witcher","cost":4,"races":["feathered"],"classes":["witcher"]},
  {"name":"doom_arbiter","cost":4,"races":["demon"],"classes":["war"]},
  {"name":"fox_blade","cost":4,"races":["beast"],"classes":["assassin"]},
  {"name":"space_walker","cost":4,"races":["beast"],"classes":["martialist"]},
  {"name":"soul_devourer","cost":4,"races":["demon"],"classes":["wizard"]},
  {"name":"cannon_granny","cost":4,"races":["goblin"],"classes":["knight"]},
  {"name":"venomancer","cost":4,"races":["goblin","kira"],"classes":["warlock"]},
  {"name":"tortola_elder","cost":4,"races":["human"],"classes":["mage"]},
  {"name":"fire_spirit","cost":4,"races":["spirit"],"classes":["warlock"]},
  {"name":"spider_queen","cost":4,"races":["insectoid"],"classes":["hunter"]},
  {"name":"siren","cost":4,"races":["marine"],"classes":["hunter"]},
  {"name":"cave_prodigy","cost":4,"races":["red"],"classes":["priest"]},
  {"name":"evernight_watcher","cost":4,"races":["halforc"],"classes":["assassin"]},
  {"name":"dragon_knight","cost":4,"races":["human","dragon"],"classes":["knight"]},
  {"name":"razorclaw","cost":4,"races":["beast"],"classes":["druid"]},
  {"name":"pirate_captain","cost":4,"races":["human"],"classes":["war"]},
  {"name":"shadowcrawler","cost":4,"races":["feathered"],"classes":["assassin"]}
]

all_units = onecost + twocost + threescost + fourescost

rate_levels = {
    "1": [100, 0, 0, 0, 0],
    "2": [85, 15, 0, 0, 0],
    "3": [70, 25, 5, 0, 0],
    "4": [55, 35, 10, 0, 0],
    "5": [45, 35, 25, 5, 0],
    "6": [30, 40, 25, 5, 0],
    "7": [25, 30, 35, 10, 0],
    "8": [20, 28, 35, 16, 1],
    "9": [20, 25, 27, 25, 3],
    "10": [15, 25, 25, 29, 6],
    "11": [15, 20, 20, 36, 9],
    "12": [15, 20, 20, 36, 9]
}

# --- Suggestion logic (adapted from your notebook) ---
def suggest_bans(user_races, user_classes, all_units, rate_levels, top_n=3):
    from collections import defaultdict
    races_cost = defaultdict(lambda: [0]*5)
    classes_cost = defaultdict(lambda: [0]*5)
    cost_totals = [0]*5
    for u in all_units:
        c = max(1, min(5, int(u.get('cost', 0))))
        idx = c-1
        cost_totals[idx] += 1
        for r in u.get('races', []):
            races_cost[r][idx] += 1
        for cl in u.get('classes', []):
            classes_cost[cl][idx] += 1
    for i in range(5):
        if cost_totals[i] == 0:
            cost_totals[i] = 1
    results = {}
    for lvl in sorted(rate_levels.keys(), key=lambda x: int(x)):
        rates = rate_levels[lvl]
        total = sum(rates) or 1
        probs = [r/total for r in rates]
        race_scores = {}
        class_scores = {}
        for r, counts in races_cost.items():
            score = sum(probs[i] * (counts[i]/cost_totals[i]) for i in range(5))
            race_scores[r] = score
        for cl, counts in classes_cost.items():
            score = sum(probs[i] * (counts[i]/cost_totals[i]) for i in range(5))
            class_scores[cl] = score
        candidates_r = [(r, s) for r, s in race_scores.items() if r not in set(user_races)]
        candidates_c = [(c, s) for c, s in class_scores.items() if c not in set(user_classes)]
        candidates_r.sort(key=lambda x: -x[1])
        candidates_c.sort(key=lambda x: -x[1])
        results[lvl] = {
            'races': [r for r, _ in candidates_r[:top_n]],
            'classes': [c for c, _ in candidates_c[:top_n]],
        }
    return results

def suggest_single_ban(user_races, user_classes, all_units, rate_levels):
    from collections import defaultdict
    races_cost = defaultdict(lambda: [0]*5)
    classes_cost = defaultdict(lambda: [0]*5)
    cost_totals = [0]*5
    for u in all_units:
        c = max(1, min(5, int(u.get('cost', 0))))
        idx = c-1
        cost_totals[idx] += 1
        for r in u.get('races', []):
            races_cost[r][idx] += 1
        for cl in u.get('classes', []):
            classes_cost[cl][idx] += 1
    for i in range(5):
        if cost_totals[i] == 0:
            cost_totals[i] = 1
    level_keys = sorted(rate_levels.keys(), key=lambda x: int(x))
    n_levels = len(level_keys) or 1
    race_scores = {r: 0.0 for r in races_cost}
    class_scores = {c: 0.0 for c in classes_cost}
    for lvl in level_keys:
        rates = rate_levels[lvl]
        total = sum(rates) or 1
        probs = [r/total for r in rates]
        for r, counts in races_cost.items():
            race_scores[r] += sum(probs[i] * (counts[i]/cost_totals[i]) for i in range(5)) / n_levels
        for cl, counts in classes_cost.items():
            class_scores[cl] += sum(probs[i] * (counts[i]/cost_totals[i]) for i in range(5)) / n_levels
    candidates_r = [(r, s) for r, s in race_scores.items() if r not in set(user_races)]
    candidates_c = [(c, s) for c, s in class_scores.items() if c not in set(user_classes)]
    candidates_r.sort(key=lambda x: -x[1])
    candidates_c.sort(key=lambda x: -x[1])
    best_r = candidates_r[0] if candidates_r else (None, 0)
    best_c = candidates_c[0] if candidates_c else (None, 0)
    if best_r[1] >= best_c[1]:
        best_overall = ('race', best_r[0], best_r[1])
    else:
        best_overall = ('class', best_c[0], best_c[1])
    return { 'best_race': best_r, 'best_class': best_c, 'best_overall': best_overall }

def _expected_desired_probability(all_units_subset, rate_levels, desired_races, desired_classes):
    # For each cost slot compute fraction of units that match desired races/classes
    cost_totals = [0]*5
    desired_counts = [0]*5
    for u in all_units_subset:
        c = max(1, min(5, int(u.get('cost', 0))))
        idx = c-1
        cost_totals[idx] += 1
        has_desired = any(r in desired_races for r in u.get('races', [])) or any(cl in desired_classes for cl in u.get('classes', []))
        if has_desired:
            desired_counts[idx] += 1
    for i in range(5):
        if cost_totals[i] == 0:
            cost_totals[i] = 1
    level_keys = sorted(rate_levels.keys(), key=lambda x: int(x))
    n_levels = len(level_keys) or 1
    total_prob = 0.0
    for lvl in level_keys:
        rates = rate_levels[lvl]
        total = sum(rates) or 1
        probs = [r/total for r in rates]
        prob_lvl = sum(probs[i] * (desired_counts[i]/cost_totals[i]) for i in range(5))
        total_prob += prob_lvl / n_levels
    return total_prob

def suggest_ban_for_desired(desired_races, desired_classes, all_units, rate_levels):
    # Evaluate banning each candidate race or class (excluding desired ones)
    desired_races = set([r.lower() for r in desired_races])
    desired_classes = set([c.lower() for c in desired_classes])

    # baseline probability (no ban)
    baseline = _expected_desired_probability(all_units, rate_levels, desired_races, desired_classes)

    # gather candidates
    all_races = sorted({r for u in all_units for r in u.get('races', [])})
    all_classes = sorted({c for u in all_units for c in u.get('classes', [])})

    best = ('none', None, baseline)

    for race in all_races:
        if race.lower() in desired_races:
            continue
        subset = [u for u in all_units if race not in u.get('races', [])]
        prob = _expected_desired_probability(subset, rate_levels, desired_races, desired_classes)
        if prob > best[2]:
            best = ('race', race, prob)

    for cl in all_classes:
        if cl.lower() in desired_classes:
            continue
        subset = [u for u in all_units if cl not in u.get('classes', [])]
        prob = _expected_desired_probability(subset, rate_levels, desired_races, desired_classes)
        if prob > best[2]:
            best = ('class', cl, prob)

    return { 'baseline': baseline, 'best_ban': best }

# --- Simple tkinter UI ---
def parse_list(s):
    return [i.strip().lower() for i in s.split(',') if i.strip()]

def get_selected_races():
    try:
        sel = listbox_races.curselection()
        return [listbox_races.get(i).lower() for i in sel]
    except Exception:
        return []

def get_selected_classes():
    try:
        sel = listbox_classes.curselection()
        return [listbox_classes.get(i).lower() for i in sel]
    except Exception:
        return []

def show_recommend_ban():
    races = get_selected_races()
    classes = get_selected_classes()
    if not races and not classes:
        txt.delete('1.0', tk.END)
        txt.insert(tk.END, 'Please select at least one desired race or class.\n')
        return
    res = suggest_ban_for_desired(races, classes, all_units, rate_levels)
    baseline = res['baseline']
    kind, name, prob = res['best_ban']
    txt.delete('1.0', tk.END)
    txt.insert(tk.END, f'Baseline probability for desired set: {baseline:.4f}\n')
    if kind == 'none' or name is None:
        txt.insert(tk.END, 'No ban candidate improves the probability.\n')
    else:
        txt.insert(tk.END, f"Recommend banning {kind}: {name} -> new probability {prob:.4f}\n")

def show_multiban():
    races = get_selected_races()
    classes = get_selected_classes()
    try:
        top_n = int(spin_top.get())
    except Exception:
        top_n = 3
    res = suggest_bans(races, classes, all_units, rate_levels, top_n=top_n)
    txt.delete('1.0', tk.END)
    for lvl, info in res.items():
        txt.insert(tk.END, f"Level {lvl}:\n")
        txt.insert(tk.END, f"  Ban races: {', '.join(info['races']) or 'None'}\n")
        txt.insert(tk.END, f"  Ban classes: {', '.join(info['classes']) or 'None'}\n")
        txt.insert(tk.END, "\n")

def show_singleban():
    races = get_selected_races()
    classes = get_selected_classes()
    res = suggest_single_ban(races, classes, all_units, rate_levels)
    txt.delete('1.0', tk.END)
    txt.insert(tk.END, f"Best single race ban: {res['best_race']}\n")
    txt.insert(tk.END, f"Best single class ban: {res['best_class']}\n")
    txt.insert(tk.END, f"Best overall to ban: {res['best_overall']}\n")

def make_ui():
    root = tk.Tk()
    root.title('Predict Ban Helper')
    root.geometry('820x520')

    style = ttk.Style()
    try:
        style.theme_use('clam')
    except Exception:
        pass
    default_font = ('Segoe UI', 10)
    header_font = ('Segoe UI', 14, 'bold')

    # main frames
    main = ttk.Frame(root, padding=(12, 12))
    main.pack(fill='both', expand=True)

    left = ttk.Frame(main)
    left.pack(side='left', fill='y', padx=(0, 12))

    right = ttk.Frame(main)
    right.pack(side='right', fill='both', expand=True)

    # available items
    available_races = sorted({r for u in all_units for r in u.get('races', [])})
    available_classes = sorted({c for u in all_units for c in u.get('classes', [])})

    ttk.Label(left, text='Your races', font=header_font).pack(anchor='w')
    races_frame = ttk.Frame(left)
    races_frame.pack(fill='y', pady=(6, 12))
    global listbox_races
    listbox_races = tk.Listbox(races_frame, selectmode='multiple', height=10, exportselection=0, font=default_font)
    rb_scroll = ttk.Scrollbar(races_frame, orient='vertical', command=listbox_races.yview)
    listbox_races.config(yscrollcommand=rb_scroll.set)
    listbox_races.pack(side='left', fill='y')
    rb_scroll.pack(side='left', fill='y', padx=(4,0))
    for it in available_races:
        listbox_races.insert(tk.END, it)

    ttk.Label(left, text='Your classes', font=header_font).pack(anchor='w')
    classes_frame = ttk.Frame(left)
    classes_frame.pack(fill='y', pady=(6, 12))
    global listbox_classes
    listbox_classes = tk.Listbox(classes_frame, selectmode='multiple', height=10, exportselection=0, font=default_font)
    cb_scroll = ttk.Scrollbar(classes_frame, orient='vertical', command=listbox_classes.yview)
    listbox_classes.config(yscrollcommand=cb_scroll.set)
    listbox_classes.pack(side='left', fill='y')
    cb_scroll.pack(side='left', fill='y', padx=(4,0))
    for it in available_classes:
        listbox_classes.insert(tk.END, it)

    # right side: options and result
    top_opts = ttk.Frame(right)
    top_opts.pack(fill='x')
    ttk.Label(top_opts, text='Predict Ban Helper', font=header_font).grid(column=0, row=0, sticky='w')
    ttk.Label(top_opts, text='Select your race(s) and class(es), then choose action.', font=default_font).grid(column=0, row=1, sticky='w', pady=(4,10))

    opts = ttk.Frame(top_opts)
    opts.grid(column=0, row=2, sticky='w')
    ttk.Label(opts, text='Top N per category', font=default_font).grid(column=0, row=0, sticky='w')
    global spin_top
    spin_top = ttk.Spinbox(opts, from_=1, to=10, width=5)
    spin_top.set('3')
    spin_top.grid(column=1, row=0, sticky='w', padx=(8,0))

    btn_frame = ttk.Frame(top_opts)
    btn_frame.grid(column=0, row=3, pady=10, sticky='w')
    ttk.Button(btn_frame, text='Show Multi-ban', command=show_multiban).pack(side='left', padx=6)
    ttk.Button(btn_frame, text='Show Single-ban', command=show_singleban).pack(side='left', padx=6)
    ttk.Button(btn_frame, text='Recommend Ban', command=lambda: show_recommend_ban()).pack(side='left', padx=6)
    ttk.Button(btn_frame, text='Clear', command=lambda: txt.delete('1.0', tk.END)).pack(side='left', padx=6)
    ttk.Button(btn_frame, text='Quit', command=root.destroy).pack(side='left', padx=6)

    # Result area
    res_frame = ttk.LabelFrame(right, text='Suggestions', padding=8)
    res_frame.pack(fill='both', expand=True)
    global txt
    txt = tk.Text(res_frame, width=60, height=20, font=('Consolas', 10), bg='#f7f7f7')
    txt.pack(fill='both', expand=True)

    # default selections (try to pre-select some common ones)
    def select_defaults():
        defaults_r = ['human', 'feathered']
        defaults_c = ['mage', 'wizard']
        for i in range(listbox_races.size()):
            if listbox_races.get(i).lower() in defaults_r:
                listbox_races.selection_set(i)
        for i in range(listbox_classes.size()):
            if listbox_classes.get(i).lower() in defaults_c:
                listbox_classes.selection_set(i)

    select_defaults()

    root.mainloop()

if __name__ == '__main__':
    make_ui()
