# DeadPlayerWalking
# DEAD PLAYER WALKING

## Game Design Document – Lab 4

**Game Title:** Dead Player Walking
**Genre:** Roguelike / Action
**Platform:** Mobile
**Team:** Tokens
**Members:** De Guzman, Asher Nathaniel E.; Macaraeg, Mark Cyrus P.; Zapanta, Zeus Levi C.
**Course:** GAMDES1 – Game Design and Development
**Section:** BSCS-IAC1
**Date:** September 22, 2026

---

# I. High Concept

## 1.1 High-Concept Statement

**Dead Player Walking** is a mobile roguelike action game where the player fights through levels, earns rewards, and permanently improves their character after every run. The main twist is that whenever the player dies, that version of the character is saved and later returns as an AI-controlled enemy that copies the player's previous actions, making every run both a chance to improve and a new challenge for future runs.

The player fantasy is to become stronger through repeated attempts while eventually fighting against the different versions of themselves that they created through their own playstyle.

---

# II. Formal Elements

## 2.1 Players

The game is designed for **one player**. The player controls a single character using touchscreen controls on a mobile device.

The player directly controls movement and combat actions while the game controls normal enemies and previous versions of the player's character through AI.

## 2.2 Objectives

The main objective is to **complete the current level by surviving enemies and reaching the level objective**.

The player also has long-term objectives:

* Improve permanent character statistics.
* Learn from previous failed runs.
* Defeat previous versions of the character.
* Survive increasingly difficult runs.
* Improve their strategy and combat performance.

## 2.3 Rules

1. The player controls one character during each run.
2. The player must remain within the playable area.
3. The player has a limited amount of health.
4. Enemy attacks reduce the player's health.
5. The player can attack enemies.
6. The player can dodge or reposition to avoid attacks.
7. Reaching the level objective completes the level.
8. If the player's health reaches zero, the player dies and the current run ends.
9. Completing a level gives the player a larger reward.
10. Dying still gives the player a smaller reward so that failure does not completely remove progress.
11. Rewards can be used to improve permanent character statistics.
12. The player's movement and combat behavior can be recorded during a run.
13. A recorded previous character can return in a future run as an AI-controlled enemy.
14. A previous character keeps the behavior and statistics from the run in which it was recorded.
15. Previous characters can accumulate across multiple runs.

## 2.4 Procedures

The basic procedure of the game is:

1. The player starts a new run.
2. The player enters the current level.
3. The player moves through the level using the touchscreen controls.
4. The player encounters normal enemies and fights them.
5. Previous versions of the player may appear as AI-controlled enemies.
6. The player attacks, dodges, and repositions during combat.
7. The player either reaches the objective or loses all health.
8. If the player completes the level, they receive a larger reward.
9. If the player dies, they receive a smaller reward.
10. The player's run can be recorded and used to create a future AI-controlled version of the player.
11. The player uses the reward to improve permanent statistics.
12. The player starts another run with their improved character.
13. More previous versions of the player may appear in later runs.

## 2.5 Resources

The main resources available to the player are:

* **Health** – determines how much damage the player can take before dying.
* **Combat abilities** – allow the player to attack and defend against enemies.
* **Rewards** – gained after completing or dying in a run and used for progression.
* **Permanent statistics** – upgrades that improve the player's character between runs.
* **Recorded behavior** – stores the player's previous movement and combat actions so they can be recreated as an AI-controlled enemy.

## 2.6 Conflict

The main conflict comes from enemies that prevent the player from safely completing the level.

There are two main types of threats:

* **Normal enemies**, which attack the player using their own AI behavior.
* **Previous player versions**, which use recorded movement and combat behavior from the player's earlier runs.

The player's own progression can also create additional conflict. As the player becomes better and records stronger runs, the future versions of the player can become more difficult to fight.

## 2.7 Boundaries

The game takes place within designated playable level areas. The player cannot freely leave the level or its combat boundaries.

The game is designed as a single-player experience and focuses on short, repeatable runs rather than an open-world environment.

The main gameplay boundary is the current level. The player must survive inside the level and reach its objective to complete the run.

## 2.8 Outcome

There are two main outcomes for a run.

**Level Completion:**
The player successfully reaches the level objective and receives a larger reward. The player can use this reward to improve permanent statistics before starting another run.

**Death:**
The player's health reaches zero and the run ends. The player still receives a smaller reward, so the run contributes to progression. The player's behavior from that run can also become a future AI-controlled version of the character.

The overall progression creates a cycle where the player becomes stronger, but also creates more versions of themselves that can become future enemies.

---

# III. Core Gameplay Loop

## 3.1 Core Loop

The core gameplay loop of **Dead Player Walking** is:

**Start Run → Move and Explore → Fight Enemies → Encounter Previous Selves → Complete Level or Die → Receive Reward → Upgrade Permanent Stats → Record Previous Run → Start Next Run**

The loop is repeated throughout the game. Each repetition allows the player to improve their character while also adding another possible version of themselves to future runs.

## 3.2 Input–Action–Feedback

### Input

The player uses touchscreen controls to:

* Move the character.
* Attack enemies.
* Dodge or reposition.
* Navigate through the level.

### Action

The player's inputs cause the character to move and perform combat actions. The player uses these actions to defeat enemies, avoid attacks, and progress toward the level objective.

### Feedback

The game provides feedback through:

* Character movement.
* Attack animations.
* Enemy reactions.
* Damage and health changes.
* Defeated enemies.
* Level completion.
* Death.
* Reward screens.
* Permanent stat upgrades.
* Previous versions of the player's character appearing in future runs.

This creates a repeatable cycle where the player makes decisions, sees the results of those decisions, and uses that experience in the next run.

## 3.3 Why the Loop Is Worth Repeating

The loop is worth repeating because the player receives progression whether they succeed or fail.

When the player completes a level, they receive a larger reward and can improve their permanent statistics. When the player dies, they receive a smaller reward instead of losing all progress. At the same time, the failed run can become a future version of the player's character.

This creates two forms of progression:

**Player progression:**
The current character becomes stronger through permanent upgrades.

**History progression:**
More previous versions of the character are created and can appear as enemies in future runs.

Because of this, every attempt changes the next attempt.

## 3.4 Core Loop Summary

**PLAY**

↓

**MOVE, ATTACK, AND DODGE**

↓

**FIGHT ENEMIES AND PREVIOUS SELVES**

↓

**COMPLETE LEVEL OR DIE**

↓

**RECEIVE REWARD**

↓

**UPGRADE PERMANENT STATS**

↓

**RECORD/SAVE THE RUN**

↓

**START NEXT RUN**

↻ **REPEAT**

The main idea of the loop is:

> **The player improves, but their past remains.**

Every run gives the player another opportunity to become stronger, but every run can also create another version of themselves that they will have to face later.
