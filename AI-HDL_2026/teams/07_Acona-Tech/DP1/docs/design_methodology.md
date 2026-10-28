# Design Methodology

(This document will be completed once Challenge-1 is announced)

## Planned Approach
1. Analyze challenge requirements thoroughly
2. Break down design into modules
3. Use AI assistance for initial implementation
4. Iterative testing and refinement
5. Comprehensive verification strategy

This document describes the methodology followed for the AI HDL 2026 design challenge. The approach is structured, iterative, and verification‑driven, with a strong emphasis on clarity, modularity, and correctness. AI tools are used as assistants, while all architectural decisions, reviews, and final implementations are owned and validated by the design team.

## 1. Overall Philosophy

The design follows a top‑down, modular, and verification‑first methodology:

Start from the system‑level requirements and specifications.

Decompose the system into well‑defined RTL modules.

Define clear interfaces and responsibilities for each block.

Implement and verify each module independently before system integration.

Iterate based on simulation results, test failures, and design reviews.

The goal is to produce clean, readable, and synthesizable RTL that is easy to verify, debug, and extend.

## 2. Requirement Analysis

Before any RTL is written, the challenge requirements are analyzed in detail:

Functional requirements (what the design must do)

Performance constraints (clock frequency, latency, throughput)

Verification and submission constraints defined by the competition

Ambiguities are resolved early by referencing standards, examples, or reasonable engineering assumptions. These assumptions are documented where relevant.

## 3. Architectural Decomposition

The system is divided into logical blocks, each with a single clear purpose. Typical blocks include:

Control logic (FSMs, configuration registers)

Datapath logic (combinational and sequential processing blocks)

Interfaces (memory, bus, or peripheral connections)

Support modules (timers, counters, glue logic)

Each module is designed to be:

Self‑contained

Parameterizable where appropriate

Independently testable( except aes_core and tqvp_aes_128 )

A block‑level diagram is created to visualize data flow and control relationships.

## 4. Interface Definition

Clear and consistent interfaces are defined before implementation:

Signal naming follows a consistent convention

Handshake signals (valid/ready, enable/done) are clearly documented

Bit widths and signal directions are fixed early to avoid integration issues

This step minimizes integration errors and simplifies verification.

## 5. RTL Implementation Strategy

RTL is written using a clean and synthesizable coding style:

SystemVerilog is used for clarity and structure

Combinational and sequential logic are clearly separated

No inferred latches or unintended combinational feedback

Parameters are used instead of hard‑coded constants when possible

AI assistance is used to:

Generate initial RTL drafts

Suggest alternative implementations

Help identify potential corner cases

All AI‑generated code is reviewed, modified, and validated by the designer.

## 6. Incremental Development

Development proceeds incrementally:

Implement the simplest functional version of a module

Verify basic functionality with directed tests

Add edge cases and stress conditions

Refine for correctness, readability, and performance

This approach reduces debugging complexity and makes failures easier to localize.

## 7. Verification Strategy

Verification is treated as a first‑class design activity:

Each RTL module has a dedicated testbench

Testbenches include:

Directed tests

Corner‑case checks

Self‑checking assertions where applicable

Waveform inspection is used to debug failures

System‑level tests are added after module‑level verification is complete.

## 8. Debug and Refinement

Simulation failures are analyzed methodically:

Verify testbench correctness first

Compare behavior against the specification

Fixes are kept minimal and targeted to avoid introducing regressions. After each fix, tests are re‑run to ensure stability.

## 9. Documentation

Documentation is maintained alongside the design:

Module descriptions and assumptions

Register maps and signal descriptions

Design decisions and trade‑offs

Known limitations or future improvement areas

This ensures the design is understandable and reviewable by others.

## 10. Final Review and Submission

Before submission:

All simulations pass without warnings or errors

RTL is lint‑clean and synthesizable

Directory structure is organized and consistent

Required documentation files are complete

The final design reflects a balance of correctness, clarity, and engineering discipline, aligned with the goals of the AI HDL 2026 challenge.
