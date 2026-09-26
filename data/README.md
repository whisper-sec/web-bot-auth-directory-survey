# The dataset

`../candidates.txt` is the population: 75 hosts.

## Where the population came from

- `from-repos.txt` (40): the declared GitHub homepage of every repository whose code references
  `http-message-signatures-directory`, `web-bot-auth` or `signature-agent`, found with GitHub code
  search.
- `operators.txt` (35): a hand-listed set of AI companies, crawler and scraping vendors,
  browser-automation services and CDNs. Hand-listed means chosen by us. That biases this half toward
  hosts we expected to find a directory on, which is worth knowing when reading the result that most
  of them did not have one.

## How 75 sources became 75 probed, which is a coincidence worth explaining

The two source files sum to 75 entries, and the population is also 75. Those are not the same 75:

- minus 1 malformed: `claude-seo.md` appears in `from-repos.txt` because that repository's GitHub
  homepage field contains a filename rather than a URL. It is a third party's metadata verbatim, left
  in the source file as evidence of how the population was derived, and rejected by the domain filter.
- minus 1 duplicate: `posthog.com` appears in both source files. **It is counted once, in the
  operators cohort.** That matters for the cohort figures in the report: it makes the repository
  cohort 38 rather than 39, and 22 absent rather than 23. Assigning it the other way would give
  23 of 39, which is 59.0% instead of 57.9%, so the choice we made lowers our own headline. We are
  noting that because a reader who counts `from-repos.txt` themselves will get 39 and should know
  why the report says 38 rather than concluding it is off by one.
- plus 2 added after review: `www.cloudflare.com` and
  `http-message-signatures-example.research.cloudflare.com`. The first because the report names it and
  a report must not name a host the dataset does not contain. The second because Cloudflare does
  publish a reference directory there, and a report saying otherwise would have been wrong.

40 + 35 - 1 - 1 + 2 = 75.

## The files

- `results.tsv` is the probe output: status, content type, final URL with query string stripped, key
  count, envelope shape, and the classification.
- `conformance.tsv` is the follow-up pass over the 17 live directories: envelope, content type,
  `alg`, and whether `kid` is the recomputed RFC 7638 thumbprint of that key rather than merely
  thumbprint-shaped.
- `controls.tsv` is the control requests for the two hosts that returned 401 or 403, probed with a
  browser User-Agent and against a nonexistent well-known path. They are what showed those refusals
  are route-level rather than aimed at our crawler, and they are published because an earlier draft
  of the report drew the opposite conclusion.

## Two corrections that changed the results

Recorded because a method that was wrong and got fixed is more useful to a reader than a method
presented as though it were right first time.

1. **Redirects.** The first probe did not pass `-L`. It would have reported `meta.com`,
   `browserbase.com`, `librechat.ai` and `usenotra.com` as having no directory. Four false negatives.
2. **Envelope.** The first key extractor accepted `{"keys":[...]}` and a bare array but not a bare
   JWK object. `shopify.com` serves a bare JWK with a correct RFC 7638 thumbprint, and it was
   therefore filed alongside HTML pages as "not a directory". One false negative, on one of the more
   conformant hosts in the set.
