#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
tmp_override="${tmp_dir}/comments-test-override.yml"
tmp_site="${tmp_dir}/site"
fixture_giscus_post="_posts/2022-01-01-comments-integration-giscus-$$.md"
fixture_disqus_post="_posts/2015-01-01-comments-integration-disqus-$$.md"
created_posts_dir=false

cleanup() {
  rm -f "${fixture_giscus_post}" "${fixture_disqus_post}"
  if [[ "${created_posts_dir}" == true ]]; then
    rmdir _posts 2>/dev/null || true
  fi
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

if [[ ! -d _posts ]]; then
  mkdir _posts
  created_posts_dir=true
fi

cat >"${fixture_giscus_post}" <<'MARKDOWN'
---
layout: post
title: Giscus comments integration fixture
permalink: /blog/2022/giscus-comments/
giscus_comments: true
---
Temporary post used by the comments integration test.
MARKDOWN

cat >"${fixture_disqus_post}" <<'MARKDOWN'
---
layout: post
title: Disqus comments integration fixture
permalink: /blog/2015/disqus-comments/
disqus_comments: true
---
Temporary post used by the comments integration test.
MARKDOWN

cat >"${tmp_override}" <<'YAML'
disqus_shortname: integration-test
giscus:
  repo: alshedivat/al-folio
  repo_id: R_kgDOExample
  category: Comments
  category_id: DIC_kwDOExample
YAML

bundle exec jekyll build --config "_config.yml,${tmp_override}" -d "${tmp_site}" >/dev/null

giscus_page="${tmp_site}/blog/2022/giscus-comments/index.html"
disqus_page="${tmp_site}/blog/2015/disqus-comments/index.html"

grep -q 'https://giscus.app/client.js' "${giscus_page}"
if grep -q 'giscus comments misconfigured' "${giscus_page}"; then
  echo "unexpected giscus misconfiguration warning in ${giscus_page}" >&2
  exit 1
fi

grep -q 'id="disqus_thread"' "${disqus_page}"
grep -q '.disqus.com/embed.js' "${disqus_page}"

echo "comments integration checks passed"
