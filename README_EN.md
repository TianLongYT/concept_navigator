# Concept Navigator

A design auxiliary tool for dismantling and reorganizing complex concepts.

[中文版本](./README.md)

---

## Table of Contents
- [1. Introduction](#1-introduction)
- [2. Design Objectives](#2-design-objectives)
- [3. Core Usage](#3-core-usage)
- [4. Environment](#4-environment)
- [5. Getting Started](#5-getting-started)

---

## 1. Introduction
Concept Navigator is a design auxiliary tool developed based on Flutter. Through its unique "Domain-Concept-Modifier" architecture, it helps designers and logical modelers dismantle complex systems into abstract concept components and perform creative concept reorganization.

---

## 2. Design Objectives
The core logic of the tool aims to simulate cognitive processes in a structured way to solve complex logic modeling problems:

*   **Concept (Concept) - Core**  
    The core unit of the system, uniquely distinguished by **Name** and **Alias** (Analogy: **Class/Class Member**). It includes three types of states:
    *   **Template (Template)**: The original defined form.
    *   **Template Reference (Template Reference)**: A direct mapping of the template; modifications sync to the source.
    *   **Reference Instance (Reference Instance)**: A variant based on the template, supporting individual modification and restoration.
*   **Domain (Domain)**  
    Used to divide the scope of concepts. Ensures isolation and organization of concepts in different contexts (Analogy: **Namespace**).
*   **Modifier (Modifier)**  
    Used to describe specific values or characteristics of a concept, providing data support for subsequent concept analysis (Analogy: **Concept instance or value**).

---

## 3. Core Usage

### Node Creation
*   Supports fast creation, naming, and management of Concept and Domain nodes.

### Hierarchical Navigation
*   **Double-click Preview**: Double-click a node to enter sub-hierarchy for details.
*   **Path Jump**: Use the top address bar to quickly switch between different paths.
*   **Global View**: Supports zooming and panning of the global viewport, providing a macro perspective.

### Node Management
*   Provides fast node searching, property editing, and cross-hierarchy moving.
*   Supports Copy, Cut, and Paste with Undo/Redo functionality.

---

## 4. Environment
*   **Multi-platform Support**: Android, iOS, Web, Windows, macOS.
*   **Interaction Optimization**:
    *   **Mobile**: Adapted for long-press interaction (long-press for 1 second to enter copy-paste mode).
    *   **PC**: Supports standard Ctrl+C/X/V shortcuts and Ctrl+Z/Y for Undo/Redo.

---

## 5. Getting Started
This project is a Flutter application.

- [Flutter Documentation](https://docs.flutter.dev/)
