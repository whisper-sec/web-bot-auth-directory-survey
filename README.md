# Who publishes a Web Bot Auth key directory: a 75-host sample

Probed 2026-09-26 by [Whisper](https://whisper.online). **We are one of the hosts in this dataset**,
and one of the seventeen reported as publishing a directory. That is a conflict of interest, and the
remedy is that the population, the script and the full results are committed here, so
every number below can be re-derived rather than believed. That mattered immediately: the first
published version of this report called our own `alg` value the single nonconformant entry in the set,
and it was wrong. See the correction below, which we have added rather than quietly editing the claim
away.

Cloudflare began challenging unverified automated traffic by default. The mechanism it offers bots
for identifying themselves honestly is Web Bot Auth: sign your requests with Ed25519 HTTP Message
Signatures (RFC 9421) and publish the public key at a well-known URL, so a relying party can verify
you without you having an account with it.

We shipped that on our own infrastructure and then went to look at who else had.

## What we did

One HTTPS GET per host for `/.well-known/http-message-signatures-directory`, redirects followed, a
User-Agent naming the study and linking to our RFC 9511 probing declaration, 0.4 seconds apart, one
pass, no retries. Query strings are stripped from recorded URLs, because a redirect chain can carry a
third party's session state and that does not belong in a published dataset.

We did not fetch `robots.txt`. For a single request to a `/.well-known/` URI that is conventional,
and we are stating it rather than leaving it to be inferred.

The population is **75 hosts**, from two sources: the declared homepages of GitHub repositories whose
code references the well-known path or `web-bot-auth`, and a hand-listed set of AI companies, crawler
and scraping vendors, browser-automation services and CDNs. Hand-listed means chosen by us, which
biases that half toward hosts we expected to find a directory on. Most of them did not have one.

**This is a sample, not a census.** It cannot tell you how many directories exist on the internet and
we make no such claim anywhere.

## What we found

Of **75 hosts probed**:

| result | hosts |
|---|---|
| serves a directory with at least one key | **17** |
| no directory (404 after redirects) | 47 |
| answers 200 with an HTML page, not a directory | 5 |
| serves a directory containing no keys | 1 |
| returned 401 or 403 on that path | 2 |
| rate-limited us | 2 |
| unreachable | 1 |

### Implementation runs well ahead of deployment

The two halves of the population answer differently, and the gap is the most useful thing here.

Among the 38 hosts that are in this study **because their repository references Web Bot Auth**, 10
serve a directory and **22 return 404 in production**. Fifty-eight per cent of the organisations that
have written code for this have not deployed it on the site the code belongs to.

Among the 35 hand-listed operators, 6 serve one and 24 do not.

We are not naming individual hosts for that gap. Source code can be a vendored dependency, an
unshipped feature, flag-gated, or deployed on a hostname we did not probe, and we did not establish
which for any of them. The rate is checkable from `data/from-repos.txt` and `data/results.tsv`; the
inference about any single company is not, so we have not made it.

### The operators you would expect are mostly absent

| host | directory |
|---|---|
| `cloudflare.com`, `www.cloudflare.com`, `developers.cloudflare.com`, `blog.cloudflare.com` | none |
| `http-message-signatures-example.research.cloudflare.com` | **yes**, 1 key (reference deployment, spec test vector) |
| `openai.com` | none |
| `chatgpt.com` | yes, 1 key |
| `anthropic.com`, `claude.ai` | none |
| `perplexity.ai` | none |
| `google.com`, `bing.com`, `duckduckgo.com`, `brave.com` | none |
| `commoncrawl.org` | none |
| `brightdata.com`, `oxylabs.io`, `zyte.com`, `apify.com` | none |
| `meta.com` | yes, 3 keys |
| `shopify.com` | yes, 1 key |

Cloudflare is the interesting case and the detail matters. They publish a **reference** directory at
`http-message-signatures-example.research.cloudflare.com`, which serves one key that is
`test-key-ed25519` from RFC 9421 Appendix B.1.4. The matching private key is printed in the RFC, so
it is demonstrably a specification example and not a production signing identity.
None of their four production hostnames serves one.

This is an incentive asymmetry. A relying party has less reason to publish than a bot operator does:
the reason to publish a key directory exists for whoever needs to get through someone else's door,
and Cloudflare is the door.

`openai.com` has no directory while `chatgpt.com` has one. The apex a person would check by hand is
not where the key is.

`scrapinghub.com` is a redirect to the Zyte homepage rather than a host with an opinion; Scrapinghub
became Zyte, so counting both is counting one operator twice.

## Conformance among the 17

All 17 serve the correct `application/http-message-signatures-directory+json` content type. Sixteen
use the `{"keys":[...]}` JWK Set; `shopify.com` serves a single bare JWK, which is a different
envelope from the one the draft shows but carries a correct key.

### The key identifier

The specification wants `kid` to be the RFC 7638 JWK thumbprint, which is what lets a verifier select
the right key from a set without being told which. We recomputed the thumbprint for every key and
compared. Twelve hosts match. Five do not:

| host | `kid` |
|---|---|
| `meta.com` | absent on all three keys |
| `metagraph.sh` | absent |
| `you.com` | absent |
| `orchestkit.yonyon.ai` | `6a120f4f14168a35`, not a thumbprint |
| `usenotra.com` | `notra-web-bot-auth-2026-01`, a human label |

A missing or arbitrary `kid` is not fatal for a directory holding one key: a verifier can simply try
it. It stops being harmless at rotation, or with more than one key. `meta.com` publishes three and
none of them carries a thumbprint.

### The algorithm, where the draft contradicts itself and the ecosystem split three ways

| `alg` | hosts |
|---|---|
| absent | 9 |
| `EdDSA` | 7 |
| `ed25519` | 1: `whisper.online`, ours |

We are not grading anybody on this row. The split is a property of the specification, not of the
operators, and the specification is the interesting part.

The word `alg` appears **exactly once** in draft-05, in this sentence, with no RFC 2119 keyword in it:

> The key directory is served as a JSON Web Key Set (JWKS) as defined in Section 5 of [JWK]. The
> "alg" parameter are restricted to algorithm registered against HTTP Signature Algorithms Section of
> [HTTP-MESSAGE-SIGNATURES-IANA]

The grammar is the draft's. That sentence does two incompatible things in twenty-eight words. It
declares the container a JWKS per RFC 7517, whose section 4.4 says `alg` values "should either be
registered in the IANA 'JSON Web Signature and Encryption Algorithms' registry established by [JWA] or
be a value that contains a Collision-Resistant Name". Then it points `alg` at a different registry
entirely: the one RFC 9421 section 6.2.2 creates, holding `rsa-pss-sha512`, `rsa-v1_5-sha256`,
`hmac-sha256`, `ecdsa-p256-sha256`, `ecdsa-p384-sha384` and `ed25519`.

No value satisfies both. The three ways the sample splits are the three reasonable responses:

- **Nine omit `alg`.** This matches all three JWKS examples printed in the draft itself, none of which
  carries an `alg` member, and RFC 7517 makes the member OPTIONAL. This is the strongest position in
  the set and it is not ours.
- **Seven publish `EdDSA`.** That is the JWA answer, which is what RFC 7517 points at. It is also the
  answer that has aged: RFC 9864 (October 2025) updates RFC 8037 and marks `EdDSA` **Deprecated** in
  the JWA registry, registering the fully-specified `Ed25519` in its place.
- **One publishes `ed25519`, ours.** That is the registry the draft's sentence names, and it is where
  we ended up by using one constant for the signature parameter and the JWK, rather than by reading
  the sentence carefully.

**Nobody in the sample publishes `Ed25519`**, the fully-specified value a current JOSE library would
actually want.

Nothing breaks either way, which is why this has gone unresolved: a verifier selects the key on `kty`
and `crv`, both of which every one of the seventeen gets right. `alg` is advisory here. But a JWKS
whose `alg` is drawn from a non-JOSE registry will be rejected by some stock JOSE parsers, and an
`EdDSA` that the JWA registry now calls deprecated is not a stable place to stand either.

Worth stating plainly: **draft-05 expired on 2026-09-03**, there is no -06, and it is an individual
submission rather than a working group document. We are filing this ambiguity with the draft's authors
rather than only writing it up here.

### One directory with no keys in it

```
$ curl -sL https://browserless.io/.well-known/http-message-signatures-directory
{
  "keys": []
}
```

`browserless.io` serves a syntactically valid directory containing no keys, with content type
`application/http-message-signatures-directory`, missing the `+json`.

The specification does not say what an operator should do before they have a key. There are two
defensible readings. An empty `keys` array is a deliberate placeholder meaning "configured, none
currently valid", which is informative if that is what you mean. A 404 means "nothing here", which is
what an unconfigured path already says. We chose the 404 for our own, on the grounds that a relying
party reading an empty array learns "this operator has no keys" rather than "this operator has not
set one up", and those are different statements. We do not know which browserless.io intends, and the
draft does not settle it.

## Two hosts answered 401 or 403 on that path

`akamai.com` returned 403 and `huggingface.co` returned 401. We ran controls before drawing any
conclusion, and the controls say this is not about our crawler:

| host | homepage, study UA | well-known, study UA | well-known, browser UA | nonexistent well-known, study UA |
|---|---|---|---|---|
| `akamai.com` | 403 | 403 | 403 | 403 |
| `huggingface.co` | 200 | 401 | 401 | 401 |

Akamai refuses this client on every path including its own homepage, to a browser User-Agent as
readily as to ours. Hugging Face serves its homepage to our study crawler and returns 401 on that
route to everybody, including for a well-known path that does not exist.

Neither is a bot-verification surface refusing a bot. An earlier draft of this report said it was,
and the controls above are what disproved it. They are published because the claim was wrong and the
correction is more useful than the anecdote would have been.

## Reproducing this

```sh
./probe.sh          # writes data/results.tsv from candidates.txt
```

That command reproduces the published dataset exactly; it follows redirects and handles the bare-JWK
envelope, both of which an earlier version did not. `data/` holds the results, the conformance table,
the controls, and a note on how the population was derived including what was filtered out of it.

Re-run it and tell us where we are wrong. The numbers will have moved by the time you read this,
which is the reason to commit a dataset rather than only a conclusion.

## What we are not claiming

We did not measure the whole internet.

We did not measure whether any of these hosts actually **signs** its outbound requests, which is the
half that matters and is much harder to observe from outside. Publishing a key costs an afternoon;
signing every request is a change to your egress path. A directory is evidence of intent, not of use.

---

### A note on the transport, which is an argument rather than a finding

Keeping this separate from the results because it is our opinion and the rest is measurement.

A key directory is served over HTTPS from an origin that may challenge automated clients. The
artifact that exists so a bot can identify itself sits behind the same defences it is trying to get
past. Nothing in this dataset proves that bites anyone, and the two 401/403 results above turned out
not to be examples of it. But the failure mode is structural, and a record resolvable from DNS and
signed by DNSSEC does not have it, because there is nothing in that path that can decide it does not
like the look of you.

We run DNS infrastructure, so treat this as interested.

## Corrections

Kept as a log rather than edited away, because a report arguing that every claim should be checkable
owes you its own history.

### 2026-09-26: we were not the nonconformant host on `alg`

**What the first published version said.** That `ed25519`, the value we publish, was "the only
non-registered `alg` in the set", that we were "the only nonconformant host", and that the section was
headed "The algorithm, where we are the outlier". The reasoning was that a JWK's `alg` is a JWA value,
that RFC 8037 section 3.1 registers `EdDSA` for Ed25519, and that we had leaked an RFC 9421
signature-parameter value into the JWK.

**Why it was wrong.** Section 3 of the draft restricts the directory's `alg` to the HTTP Signature
Algorithms registry, not to the JOSE one. `ed25519` is in that registry; `EdDSA` is not. We had graded
our own value against a registry the draft does not name, which is the same class of mistake the
sentence was accusing the value of.

Two checks, either of which would have caught it, neither of which we ran before publishing:

```sh
# the registry the draft actually names: six values, ed25519 among them, no EdDSA
curl -s https://www.iana.org/assignments/http-message-signature/http-message-signature.xml \
  | sed -n '/signature-algorithms/,/<\/registry>/p' | grep '<name>'

# and the sentence itself, which is the only occurrence of alg in the document
curl -s https://www.ietf.org/archive/id/draft-meunier-http-message-signatures-directory-05.txt \
  | sed -n '/key directory is served/,/HTTP-MESSAGE-SIGNATURES-IANA/p'
```

**A second thing the original got wrong.** It treated RFC 8037 as current. RFC 9864 (October 2025)
updates RFC 8037 and marks `EdDSA` **Deprecated** in the JOSE registry.

**What we did not do in response.** The obvious correction was to reverse the charge and report seven
named hosts as nonconformant instead. We have not, and the rewritten section grades nobody. The draft
names one registry, RFC 7517 names another, the draft's own examples use neither, and no published
value satisfies both halves of the sentence. That is a specification defect, and turning it into a
scoreboard aimed at seven third parties would have been a worse error than the one being fixed, because
it would have been aimed outward.

**What changed in our infrastructure.** Nothing that anyone was served. A fix was staged internally to
change our published `alg` to `EdDSA`, which would have moved us onto a deprecated value from a registry
the draft does not name. It was reverted before deploying. The live directory has served `ed25519`
throughout and still does.

**What we are doing upstream.** Taking it to the draft rather than only writing it up here, since a
specification ambiguity that splits seventeen deployments three ways belongs with its authors. The issue
is being filed against the draft's tracker as this correction goes out, and this line will be updated
with the number:
https://github.com/thibmeu/http-message-signatures-directory/issues
