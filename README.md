# agent-tools

Kezdő repository AI-alapú fejlesztői eszközöknek: saját skill-ekhez, agent-ekhez, instruction fájlokhoz és egyéb újrahasznosítható prompt-alapú komponensekhez.

## Mi van ebben a repo-ban?

- `skills/`: újrahasznosítható, domain-specifikus skill-ek
- `agents/`: specializált agent definíciók és workflow-k
- `.github/instructions/`: repository- vagy témaspecifikus instruction fájlok
- `copilot-instructions.md`: globális útmutató ehhez a repo-hoz
- `AGENTS.md`: agent-eknek szóló, technikai működési dokumentáció

## Kezdő struktúra

```text
.
├── .github/
│   └── instructions/
│       └── general.instructions.md
├── agents/
│   └── repo-architect.agent.md
├── skills/
│   └── example-skill/
│       └── SKILL.md
├── AGENTS.md
├── copilot-instructions.md
├── .gitignore
└── README.md
```

## Mire jó ez a repo?

- saját Copilot/agent workflow-k központi tárolására
- skill-ek és prompt sablonok verziókezelésére
- csapaton belüli AI fejlesztési minták egységesítésére
- gyors bootstrap alapként új agent-eszközök építéséhez

## Első lépések

1. Másolj egy meglévő skill mappát a `skills/` alá, és szabd testre.
2. Hozz létre új agent definíciót az `agents/` alatt.
3. Bővítsd a `.github/instructions/` tartalmát projektspecifikus szabályokkal.
4. Frissítsd az `AGENTS.md` fájlt, ha a workflow vagy a struktúra változik.

## Javasolt bővítések

- több skill külön domainekre, például review, refaktor, dokumentáció
- dedikált agent-ek kutatáshoz, scaffoldoláshoz vagy ellenőrzéshez
- tesztelt prompt könyvtár gyakori feladatokra
- példaprojektek vagy referencia bemenetek a skill-ek mellé

## Állapot

Ez a repository egy szándékosan kicsi, de használható bootstrap alap. A következő lépés tipikusan a saját skill-ek és agent-ek finomhangolása.