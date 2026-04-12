// ─────────────────────────────────────────────────────────────
// IngredientMatcher — O(1) exact · longest-match trie · fuzzy
// ─────────────────────────────────────────────────────────────

import { CanonicalIngredient, MatchCandidate } from "./types";

// ── Trie Node ──────────────────────────────────────────────────

interface TrieNode {
  children: Map<string, TrieNode>;
  /** If defined, this node terminates a complete alias → canonical ID */
  canonicalId?: string;
}

// ── Longest Match Result ───────────────────────────────────────

export interface LongestMatchResult {
  canonicalId: string;
  startIndex: number;
  endIndex: number;
  matchedTokens: string[];
}

// ── IngredientMatcher ──────────────────────────────────────────

export class IngredientMatcher {
  /** O(1) exact lookup: normalized alias → canonical ID */
  private exactMap = new Map<string, string>();

  /** Multi-word trie for longest-match */
  private trieRoot: TrieNode = { children: new Map() };

  /** Inverted index: token → set of canonical IDs (for fuzzy scoring) */
  private tokenIndex = new Map<string, Set<string>>();

  /** Canonical ingredients by ID */
  private canonicals = new Map<string, CanonicalIngredient>();

  /** Duplicate alias tracker (for build-time warnings) */
  private duplicates: Array<{ alias: string; existingId: string; newId: string }> = [];

  constructor(
    ingredients: Record<string, CanonicalIngredient>,
    aliasData: Record<string, string[]>,
  ) {
    // Store canonicals
    for (const [id, ingredient] of Object.entries(ingredients)) {
      this.canonicals.set(id, ingredient);
    }

    // Build indexes from alias data
    for (const [canonicalId, aliases] of Object.entries(aliasData)) {
      for (const rawAlias of aliases) {
        const normalized = rawAlias.toLowerCase().trim();
        if (normalized.length === 0) continue;

        // --- Exact map (detect duplicates) ---
        const existing = this.exactMap.get(normalized);
        if (existing && existing !== canonicalId) {
          this.duplicates.push({ alias: normalized, existingId: existing, newId: canonicalId });
        }
        this.exactMap.set(normalized, canonicalId);

        // --- Trie insertion ---
        const tokens = normalized.split(/\s+/);
        let node = this.trieRoot;
        for (const token of tokens) {
          if (!node.children.has(token)) {
            node.children.set(token, { children: new Map() });
          }
          node = node.children.get(token)!;
        }
        node.canonicalId = canonicalId;

        // --- Token inverted index ---
        for (const token of tokens) {
          if (!this.tokenIndex.has(token)) {
            this.tokenIndex.set(token, new Set());
          }
          this.tokenIndex.get(token)!.add(canonicalId);
        }
      }
    }
  }

  /** Get any detected duplicate aliases (for debugging / QA). */
  getDuplicates() {
    return this.duplicates;
  }

  /** Get a canonical ingredient by ID. */
  getCanonical(id: string): CanonicalIngredient | undefined {
    return this.canonicals.get(id);
  }

  /** Total number of aliases indexed. */
  get aliasCount(): number {
    return this.exactMap.size;
  }

  // ── Exact Match ──────────────────────────────────────────────

  /**
   * O(1) exact lookup of a normalized alias string.
   * Returns the canonical ID or undefined.
   */
  exactMatch(normalizedText: string): string | undefined {
    return this.exactMap.get(normalizedText);
  }

  // ── Longest Match (Trie) ─────────────────────────────────────

  /**
   * Find the longest alias that matches a contiguous subsequence of tokens.
   * Tries every starting position; returns the match covering the most tokens.
   * Complexity: O(n × m) where n = token count, m = max alias length — both tiny.
   */
  longestMatch(tokens: string[]): LongestMatchResult | null {
    let best: LongestMatchResult | null = null;

    for (let i = 0; i < tokens.length; i++) {
      let node = this.trieRoot;
      for (let j = i; j < tokens.length; j++) {
        const child = node.children.get(tokens[j]);
        if (!child) break;
        node = child;
        if (node.canonicalId) {
          const length = j - i + 1;
          if (!best || length > best.endIndex - best.startIndex + 1) {
            best = {
              canonicalId: node.canonicalId,
              startIndex: i,
              endIndex: j,
              matchedTokens: tokens.slice(i, j + 1),
            };
          }
        }
      }
    }

    return best;
  }

  // ── Fuzzy Match (Token Overlap) ──────────────────────────────

  /**
   * Score candidates by token overlap (F1-style).
   * Returns up to `topN` candidates above `threshold`.
   */
  fuzzyMatch(tokens: string[], topN = 3, threshold = 0.25): MatchCandidate[] {
    const scores = new Map<string, number>();

    for (const token of tokens) {
      const ids = this.tokenIndex.get(token);
      if (ids) {
        for (const id of ids) {
          scores.set(id, (scores.get(id) ?? 0) + 1);
        }
      }
    }

    const candidates: MatchCandidate[] = [];
    for (const [id, shared] of scores) {
      const canonical = this.canonicals.get(id);
      const aliasTokenCount = canonical
        ? canonical.name.toLowerCase().split(/\s+/).length
        : 1;

      const precision = shared / tokens.length;
      const recall = shared / Math.max(aliasTokenCount, 1);
      const f1 = (2 * precision * recall) / (precision + recall + 1e-9);

      if (f1 >= threshold) {
        candidates.push({
          id,
          score: Math.round(f1 * 1000) / 1000,
          matchedTokens: tokens.filter((t) => this.tokenIndex.get(t)?.has(id)),
        });
      }
    }

    return candidates.sort((a, b) => b.score - a.score).slice(0, topN);
  }
}
