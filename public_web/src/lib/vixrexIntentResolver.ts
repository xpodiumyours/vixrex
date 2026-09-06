import matcherContract from "../../../shared/vixrex_matcher_contract.json";
import { VIXREX_NIYET_SOZLUGU, type VixrexNiyetAlan } from "./vixrexNiyetSozlugu";
import { vixrexNormalizeDartParity } from "./vixrexNormalizer";

export type VixrexMatchClass = "exact_phrase" | "exact_token" | "inflected_safe";

export interface VixrexIntentMatch {
  alan: VixrexNiyetAlan;
  matchedAlias: string;
  matchClass: VixrexMatchClass;
  startToken: number;
  endToken: number;
}

type Candidate = VixrexIntentMatch & {
  aliasLength: number;
  tokenCount: number;
};

type MatcherContract = {
  minInflectedAliasLength: number;
  safeSuffixes: string[];
  exactFormsByField: Record<string, string[]>;
};

const CONTRACT = matcherContract as MatcherContract;
const SAFE_SUFFIXES = [...CONTRACT.safeSuffixes].sort((a, b) => b.length - a.length);

function tokenize(text: string): string[] {
  const normalized = vixrexNormalizeDartParity(text);
  return normalized.match(/[a-z0-9]+/g) ?? [];
}

function classRank(matchClass: VixrexMatchClass): number {
  switch (matchClass) {
    case "exact_phrase":
      return 3;
    case "exact_token":
      return 2;
    case "inflected_safe":
      return 1;
  }
}

function isSafeInflection(inputToken: string, aliasToken: string): boolean {
  if (!inputToken.startsWith(aliasToken) || inputToken.length <= aliasToken.length) return false;
  const suffix = inputToken.slice(aliasToken.length);
  return SAFE_SUFFIXES.includes(suffix);
}

function collectFormMatches(
  inputTokens: string[],
  alan: VixrexNiyetAlan,
  form: string,
  allowInflected: boolean,
): Candidate[] {
  const aliasTokens = tokenize(form);
  if (aliasTokens.length === 0 || aliasTokens.length > inputTokens.length) return [];

  const normalizedAliasLength = aliasTokens.join("").length;
  const out: Candidate[] = [];

  for (let start = 0; start <= inputTokens.length - aliasTokens.length; start += 1) {
    let prefixMatches = true;
    for (let offset = 0; offset < aliasTokens.length - 1; offset += 1) {
      if (inputTokens[start + offset] !== aliasTokens[offset]) {
        prefixMatches = false;
        break;
      }
    }
    if (!prefixMatches) continue;

    const end = start + aliasTokens.length - 1;
    const inputLast = inputTokens[end];
    const aliasLast = aliasTokens[aliasTokens.length - 1];

    if (inputLast === aliasLast) {
      out.push({
        alan,
        matchedAlias: form,
        matchClass: aliasTokens.length > 1 ? "exact_phrase" : "exact_token",
        startToken: start,
        endToken: end,
        aliasLength: normalizedAliasLength,
        tokenCount: aliasTokens.length,
      });
      continue;
    }

    if (
      allowInflected &&
      normalizedAliasLength >= CONTRACT.minInflectedAliasLength &&
      isSafeInflection(inputLast, aliasLast)
    ) {
      out.push({
        alan,
        matchedAlias: form,
        matchClass: "inflected_safe",
        startToken: start,
        endToken: end,
        aliasLength: normalizedAliasLength,
        tokenCount: aliasTokens.length,
      });
    }
  }

  return out;
}

function sameScore(a: Candidate, b: Candidate): boolean {
  return (
    classRank(a.matchClass) === classRank(b.matchClass) &&
    a.tokenCount === b.tokenCount &&
    a.aliasLength === b.aliasLength
  );
}

function overlaps(a: Candidate, b: Candidate): boolean {
  return a.startToken <= b.endToken && b.startToken <= a.endToken;
}

function selectSafeMatches(candidates: Candidate[]): VixrexIntentMatch[] {
  const sorted = [...candidates].sort((a, b) => {
    const rank = classRank(b.matchClass) - classRank(a.matchClass);
    if (rank !== 0) return rank;
    const tokens = b.tokenCount - a.tokenCount;
    if (tokens !== 0) return tokens;
    const length = b.aliasLength - a.aliasLength;
    if (length !== 0) return length;
    const start = a.startToken - b.startToken;
    if (start !== 0) return start;
    return a.alan.anahtar.localeCompare(b.alan.anahtar, "tr");
  });

  const accepted: Candidate[] = [];
  for (const candidate of sorted) {
    const ambiguous = sorted.some(
      (other) =>
        other !== candidate &&
        other.alan.anahtar !== candidate.alan.anahtar &&
        other.startToken === candidate.startToken &&
        other.endToken === candidate.endToken &&
        sameScore(other, candidate),
    );
    if (ambiguous) continue;
    if (accepted.some((other) => overlaps(other, candidate))) continue;
    accepted.push(candidate);
  }

  accepted.sort((a, b) => a.startToken - b.startToken || a.endToken - b.endToken);
  return accepted.map(({ aliasLength: _aliasLength, tokenCount: _tokenCount, ...match }) => match);
}

export function resolveVixrexIntentMatches(input: string): VixrexIntentMatch[] {
  const inputTokens = tokenize(input);
  if (inputTokens.length === 0) return [];

  const candidates: Candidate[] = [];
  for (const alan of VIXREX_NIYET_SOZLUGU) {
    for (const alias of alan.esAnlamlar) {
      candidates.push(...collectFormMatches(inputTokens, alan, alias, true));
    }

    const exactForms = CONTRACT.exactFormsByField[alan.anahtar] ?? [];
    for (const exactForm of exactForms) {
      candidates.push(...collectFormMatches(inputTokens, alan, exactForm, false));
    }
  }

  return selectSafeMatches(candidates);
}

export function resolveVixrexIntent(input: string): VixrexNiyetAlan | null {
  return resolveVixrexIntentMatches(input)[0]?.alan ?? null;
}

export function resolveVixrexIntentsAll(input: string): VixrexNiyetAlan[] {
  const seen = new Set<string>();
  const fields: VixrexNiyetAlan[] = [];
  for (const match of resolveVixrexIntentMatches(input)) {
    if (seen.has(match.alan.anahtar)) continue;
    seen.add(match.alan.anahtar);
    fields.push(match.alan);
  }
  return fields;
}
