# Steuerung und Verwendung einer lokalen ollama Instanz
Nutzung als Skill und/oder Agent
**Ermitteln welche Variante sinnvoller ist**


## Idee
Agents sollen nach Möglichkeit ein lokales llm in meiner ollama Instanz verwenden.
Es soll ein Skill/(sub)Agent entstehen der dies ermöglicht und vereinfacht

## Möglichkeiten / Fähigkeiten
- Prüfen ob ob die lokale Instanz gestartet ist
-- einfache curl Abfrage ob die Instanz verfügbar ist
-- Laufende Modelle prüfen `ollama ps`, Ergebnis kann leer sein
- Bei bedarf Docker Instanz starten
- ein modell im ollame starten `ollama run [MODELNAME]`

### Lokale Instanz
Meine Lokale Instanz läuft innerhalb eines Docker Container. Dieser muss also gestartet sein damit meien Instanz erreichbar ist.

```bash
docker container ls --all
docker ps
```

- Beispielname fuer meine Intel-Docker-Umgebung: `intel-llm`

## Liste verfügbarer llm
- Es soll eine Liste mit den in meiner Instanz verfügbaren Modellen erstell, gepflegt und aktualisiert werden

```bash
ollama list
```

### Beispiel Liste, Markdown formatiert

Referenz: **[`modellkatalog.md`](modellkatalog.md)**


## Model Test
Es soll ein einfacher Test für ein beliebiges (als Parameter, aus auswahl aus Liste) möglich sein.
Dies soll ein einfaches `Hellp World` Beispiel in eine C# Datei schreiben. 
Gemessen werden soll die Qualität des Ergebnis und die Dauer.

Alternativ ein Beispiel mit GDScript um die Leistung für die Verwendung mit Godot Projekten zu bewerten. Wissenstand sollte die Godot Engine 4.x enthalten. Modelle die die Version 4 nicht abdecken können, fallen raus.

Sollte ein Modell nicht geladen werden können oder in irgendeiner Weise Fehkerhaft, dann soll diese in der Liste der Lokalen LLM entsprechend vermerkt werden

## Implementierung

1. Analysieren dieser Anforderungen
    * Entscheiden ob Skill oder Agent 
2. Ergänzen nicht bedachter Punkte oder voraussetzungen
3. Erstellen einer ersten Struktur für diesen Skill / Agent
4. Implementierung der Funktion
### Prio

- Prüfen der Verfügbarkeit
  - Docker (ist der Container nicht gestartet, dann ist ollama nicht verfügbar)
- Liste der ollama llm
  - Erstellen, aktualisieren
- Bei bedarf ein neues llm herunterladen und in der Instanz verfügbar machen
    ```
    ollama pull [Model Name]
    ```
- Einfacher Coding Test
