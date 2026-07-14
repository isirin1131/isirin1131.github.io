from __future__ import annotations

import html
import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote


ROOT = Path(__file__).resolve().parent
OBJECT_DIR = ROOT / "object"
ASSETS_DIR = ROOT / "assets"
GALLERY_ITEMS_DIR = ROOT / "gallery" / "items"
SITE_TITLE = "zhecai's blog"
PUBLIC_DIR_RE = re.compile(r"^\[(\d{3})\](.+)$")
IMAGE_EXTENSIONS = {
    ".apng",
    ".avif",
    ".bmp",
    ".gif",
    ".heic",
    ".heif",
    ".ico",
    ".jfif",
    ".jpeg",
    ".jpg",
    ".jxl",
    ".png",
    ".svg",
    ".tif",
    ".tiff",
    ".webp",
}

DEFAULT_TYPST_FONT = """#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))
#show math.equation: set text(font: "Neo Euler")
论文字体：
#set text(
  // 英文优先使用 New Computer Modern (学术巅峰)
  // 中文自动回退到 Source Han Serif SC (现代正式)
  font: ("New Computer Modern", "Source Han Serif SC"),
  lang: "zh"
)"""


@dataclass
class Entry:
    title: str
    filename: str
    extension: str
    category_title: str
    category_dir: str
    path: Path
    published: str | None
    updated: str | None


@dataclass
class Category:
    index: int
    dir_name: str
    title: str
    path: Path
    entries: list[Entry]

    @property
    def output_name(self) -> str:
        return f"{self.dir_name}.html"

    @property
    def updated(self) -> str | None:
        dates = [entry.updated for entry in self.entries if entry.updated]
        return max(dates) if dates else None

    @property
    def file_types(self) -> list[str]:
        return sorted({entry.extension for entry in self.entries}, key=natural_sort_key)


@dataclass
class GalleryItem:
    id: str
    title: str
    date: str
    image: str
    alt: str
    source: str
    body: str


def natural_sort_key(value: object) -> list[object]:
    """Return a stable natural sort key for mixed Chinese/ASCII filenames."""

    def convert(text: str) -> object:
        return int(text) if text.isdigit() else text.casefold()

    return [convert(part) for part in re.split(r"([0-9]+)", str(value))]


def h(value: object) -> str:
    return html.escape(str(value), quote=True)


def quote_url_path(*parts: str) -> str:
    return "/".join(quote(part, safe="-_.~()") for part in parts)


def root_href(path: Path) -> str:
    rel_path = path.relative_to(ROOT) if path.is_absolute() else path
    return f"./{quote_url_path(*rel_path.parts)}"


def date_value(value: str | None) -> str:
    return value if value else "0000-00-00"


def time_html(value: str | None) -> str:
    if not value:
        return '<span class="date-unknown">未记录</span>'
    return f'<time datetime="{h(value)}">{h(value)}</time>'


def display_type(extension: str) -> str:
    return extension.upper() if extension else "FILE"


def git_dates(path: Path) -> tuple[str | None, str | None]:
    rel_path = path.relative_to(ROOT).as_posix()
    try:
        result = subprocess.run(
            ["git", "log", "--follow", "--format=%ad", "--date=short", "--", rel_path],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
    except OSError:
        return None, None

    if result.returncode != 0:
        return None, None

    dates = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if not dates:
        return None, None

    return dates[-1], dates[0]


def collect_categories() -> list[Category]:
    categories: list[Category] = []

    for path in ROOT.iterdir():
        match = PUBLIC_DIR_RE.match(path.name)
        if not match or not path.is_dir():
            continue

        entries: list[Entry] = []
        for item in sorted(path.iterdir(), key=lambda candidate: natural_sort_key(candidate.name)):
            if not item.is_file() or item.name.startswith("."):
                continue

            published, updated = git_dates(item)
            extension = item.suffix.lower().lstrip(".") or "file"
            entries.append(
                Entry(
                    title=item.stem,
                    filename=item.name,
                    extension=extension,
                    category_title=match.group(2),
                    category_dir=path.name,
                    path=item,
                    published=published,
                    updated=updated,
                )
            )

        categories.append(
            Category(
                index=int(match.group(1)),
                dir_name=path.name,
                title=match.group(2),
                path=path,
                entries=entries,
            )
        )

    return sorted(categories, key=lambda category: natural_sort_key(category.dir_name))


def recent_entries(entries: list[Entry], limit: int | None = None) -> list[Entry]:
    by_name = sorted(entries, key=lambda entry: natural_sort_key(entry.title))
    ordered = sorted(
        by_name,
        key=lambda entry: (date_value(entry.updated), date_value(entry.published)),
        reverse=True,
    )
    return ordered[:limit] if limit else ordered


def type_counts(entries: list[Entry]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for entry in entries:
        counts[entry.extension] = counts.get(entry.extension, 0) + 1
    return dict(sorted(counts.items(), key=lambda item: natural_sort_key(item[0])))


def read_typst_font() -> str:
    path = ROOT / "typstFontSetting.txt"
    try:
        text = path.read_text(encoding="utf-8").strip()
    except OSError:
        return DEFAULT_TYPST_FONT
    return text or DEFAULT_TYPST_FONT


def first_markdown_heading(body: str) -> str | None:
    for line in body.splitlines():
        match = re.match(r"^#\s+(.+)$", line.strip())
        if match:
            return match.group(1).strip()
    return None


def gallery_folder_files(path: Path) -> tuple[Path | None, Path | None]:
    markdown_files = sorted(
        (
            item
            for item in path.iterdir()
            if item.is_file() and item.suffix.lower() == ".md" and not item.name.startswith((".", "_"))
        ),
        key=lambda item: natural_sort_key(item.name),
    )
    image_files = sorted(
        (
            item
            for item in path.iterdir()
            if item.is_file() and item.suffix.lower() in IMAGE_EXTENSIONS and not item.name.startswith(".")
        ),
        key=lambda item: natural_sort_key(item.name),
    )
    return (markdown_files[0] if markdown_files else None, image_files[0] if image_files else None)


def gallery_item_date(markdown_path: Path, image_path: Path) -> str:
    dates: list[str] = []
    for path in (markdown_path, image_path):
        _, updated = git_dates(path)
        if updated:
            dates.append(updated)
    return max(dates) if dates else ""


def collect_gallery_items() -> list[GalleryItem]:
    if not GALLERY_ITEMS_DIR.exists():
        return []

    items: list[GalleryItem] = []
    for path in sorted(GALLERY_ITEMS_DIR.iterdir(), key=lambda candidate: natural_sort_key(candidate.name)):
        if not path.is_dir() or path.name.startswith((".", "_")):
            continue

        markdown_path, image_path = gallery_folder_files(path)
        if not markdown_path or not image_path:
            continue

        body = markdown_path.read_text(encoding="utf-8").strip()
        title = first_markdown_heading(body) or path.name
        items.append(
            GalleryItem(
                id=path.name,
                title=title,
                date=gallery_item_date(markdown_path, image_path),
                image=root_href(image_path),
                alt=title,
                source=root_href(markdown_path),
                body=body,
            )
        )

    return items


def gallery_json(items: list[GalleryItem]) -> str:
    data = [
        {
            "id": item.id,
            "title": item.title,
            "date": item.date,
            "image": item.image,
            "alt": item.alt,
            "source": item.source,
            "body": item.body,
        }
        for item in items
    ]
    return json.dumps(data, ensure_ascii=False).replace("</", "<\\/")


def page_head(title: str, asset_prefix: str) -> str:
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{h(title)}</title>
  <link rel="stylesheet" href="{asset_prefix}assets/site.css">
  <script defer src="{asset_prefix}assets/site.js"></script>
</head>
"""


def site_header(categories: list[Category], current: Category | None, asset_prefix: str) -> str:
    home_link = f"{asset_prefix}index.html"
    nav_links = []
    for category in categories:
        if current and category.dir_name == current.dir_name:
            nav_links.append(
                f'<a href="./{quote_url_path(category.output_name)}" aria-current="page">{h(category.title)}</a>'
            )
        else:
            nav_links.append(
                f'<a href="{asset_prefix}object/{quote_url_path(category.output_name)}">{h(category.title)}</a>'
            )
    nav_links.append(f'<a href="{asset_prefix}gallery.html">画廊</a>')

    return f"""<body>
  <a class="skip-link" href="#content">跳到正文</a>
  <header class="site-header">
    <a class="brand" href="{home_link}">{h(SITE_TITLE)}</a>
    <nav class="site-nav" aria-label="分类">
      {"".join(nav_links)}
    </nav>
  </header>
"""


def site_footer() -> str:
    return f"""  <footer class="site-footer">
    <p>{h(SITE_TITLE)}</p>
  </footer>
</body>
</html>
"""


def root_resource_href(entry: Entry) -> str:
    return f"./{quote_url_path(entry.category_dir, entry.filename)}"


def archive_resource_href(entry: Entry) -> str:
    return f"../{quote_url_path(entry.category_dir, entry.filename)}"


def category_page_href(category: Category, asset_prefix: str) -> str:
    return f"{asset_prefix}object/{quote_url_path(category.output_name)}"


def render_entry_line(entry: Entry, href: str, include_category: bool = False) -> str:
    category = f'<span class="entry-category">{h(entry.category_title)}</span>' if include_category else ""
    return f"""<li class="entry-line">
  <a href="{href}" target="_blank" rel="noopener">{h(entry.title)}</a>
  <span class="file-badge">{h(display_type(entry.extension))}</span>
  {category}
  <span class="date-label">更新 {time_html(entry.updated)}</span>
</li>"""


def render_home(categories: list[Category]) -> str:
    entries = [entry for category in categories for entry in category.entries]
    latest = recent_entries(entries, limit=10)
    latest_update = max((entry.updated for entry in entries if entry.updated), default=None)
    counts = type_counts(entries)
    typst_font = read_typst_font()

    type_summary = " / ".join(
        f"{h(display_type(file_type))} {count}" for file_type, count in counts.items()
    )
    latest_lines = "\n".join(
        render_entry_line(entry, root_resource_href(entry), include_category=True) for entry in latest
    )

    category_cards = []
    for category in categories:
        card_entries = "\n".join(
            render_entry_line(entry, root_resource_href(entry)) for entry in recent_entries(category.entries, limit=5)
        )
        type_labels = " ".join(
            f'<span class="type-chip">{h(display_type(file_type))}</span>' for file_type in category.file_types
        )
        category_cards.append(
            f"""<article class="category-card">
  <div class="category-meta">
    <span>{h(category.dir_name[:5])}</span>
    <span>{len(category.entries)} 篇</span>
    <span>更新 {time_html(category.updated)}</span>
  </div>
  <h3><a href="{category_page_href(category, './')}">{h(category.title)}</a></h3>
  <div class="type-row">{type_labels}</div>
  <ol class="entry-list">
    {card_entries}
  </ol>
</article>"""
        )

    category_grid = "\n".join(category_cards)

    return (
        page_head(SITE_TITLE, "./")
        + site_header(categories, None, "./")
        + f"""  <main id="content">
    <section class="home-hero">
      <p class="eyebrow">Personal Magazine / Static Archive</p>
      <div class="hero-grid">
        <div>
          <h1>{h(SITE_TITLE)}</h1>
          <p class="lead">我终于不再梦到那宏大的寂静、收缩或撕裂。</p>
        </div>
        <dl class="stat-grid" aria-label="站点统计">
          <div>
            <dt>分类</dt>
            <dd>{len(categories)}</dd>
          </div>
          <div>
            <dt>内容</dt>
            <dd>{len(entries)}</dd>
          </div>
          <div>
            <dt>最近更新</dt>
            <dd>{time_html(latest_update)}</dd>
          </div>
          <div>
            <dt>类型</dt>
            <dd>{type_summary or "未记录"}</dd>
          </div>
        </dl>
      </div>
    </section>

    <section class="section-block" aria-labelledby="latest-title">
      <div class="section-heading">
        <p class="eyebrow">Recently Updated</p>
        <h2 id="latest-title">最近更新</h2>
      </div>
      <ol class="entry-list latest-list">
        {latest_lines}
      </ol>
    </section>

    <section class="section-block" aria-labelledby="categories-title">
      <div class="section-heading">
        <p class="eyebrow">Archives</p>
        <h2 id="categories-title">分类归档</h2>
      </div>
      <div class="category-grid">
        {category_grid}
      </div>
    </section>

    <section class="info-strip" aria-label="联系与资源">
      <details class="info-panel" data-fold>
        <summary>
          <span>联系与资源</span>
          <span data-fold-state>展开</span>
        </summary>
        <div class="info-grid">
          <section>
            <h2>联系方式</h2>
            <p>email: <a href="mailto:13793971886@139.com">13793971886@139.com</a></p>
            <p>qq: 3632915050</p>
            <p>wechat: telzert</p>
          </section>
          <section>
            <h2>Typst 字体</h2>
            <pre><code>{h(typst_font)}</code></pre>
          </section>
          <section>
            <h2>友情链接</h2>
            <p><a href="http://zelog.xyz/" target="_blank" rel="noopener">zelog.xyz</a></p>
          </section>
        </div>
      </details>
    </section>
  </main>
"""
        + site_footer()
    )


def render_archive_page(category: Category, categories: list[Category]) -> str:
    entries = recent_entries(category.entries)
    type_buttons = ['<button type="button" class="filter-pill is-active" data-filter="all" aria-pressed="true">全部</button>']
    for file_type in category.file_types:
        type_buttons.append(
            f'<button type="button" class="filter-pill" data-filter="{h(file_type)}" aria-pressed="false">{h(display_type(file_type))}</button>'
        )

    entry_items = []
    for entry in entries:
        entry_items.append(
            f"""<li class="archive-entry"
  data-entry
  data-type="{h(entry.extension)}"
  data-title="{h(entry.title)}"
  data-published="{h(entry.published or "")}"
  data-updated="{h(entry.updated or "")}">
  <div class="archive-entry-main">
    <a href="{archive_resource_href(entry)}" target="_blank" rel="noopener">{h(entry.title)}</a>
    <span class="file-badge">{h(display_type(entry.extension))}</span>
  </div>
  <dl class="entry-dates">
    <div>
      <dt>首次发布</dt>
      <dd>{time_html(entry.published)}</dd>
    </div>
    <div>
      <dt>最近更新</dt>
      <dd>{time_html(entry.updated)}</dd>
    </div>
  </dl>
</li>"""
        )

    entries_html = "\n".join(entry_items)

    return (
        page_head(f"{category.title} - {SITE_TITLE}", "../")
        + site_header(categories, category, "../")
        + f"""  <main id="content">
    <section class="archive-hero">
      <p class="eyebrow">Archive / {h(category.dir_name[:5])}</p>
      <h1>{h(category.title)}</h1>
      <dl class="stat-grid compact" aria-label="分类统计">
        <div>
          <dt>内容</dt>
          <dd>{len(category.entries)}</dd>
        </div>
        <div>
          <dt>最近更新</dt>
          <dd>{time_html(category.updated)}</dd>
        </div>
      </dl>
    </section>

    <section class="archive-panel" data-archive>
      <div class="archive-toolbar">
        <div class="filter-group" role="group" aria-label="文件类型">
          {"".join(type_buttons)}
        </div>
        <label class="sort-control">
          <span>排序</span>
          <select data-sort>
            <option value="updated-desc">最近更新</option>
            <option value="published-desc">首次发布</option>
            <option value="title-asc">标题</option>
          </select>
        </label>
      </div>
      <p class="result-line"><span data-result-count>{len(category.entries)} 篇</span></p>
      <ol class="archive-list" data-entry-list>
        {entries_html}
      </ol>
    </section>
  </main>
"""
        + site_footer()
    )


def render_gallery_page(items: list[GalleryItem]) -> str:
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gallery - {h(SITE_TITLE)}</title>
  <link rel="stylesheet" href="./assets/site.css">
  <link rel="stylesheet" href="./assets/gallery.css">
  <script type="application/json" id="gallery-data">{gallery_json(items)}</script>
  <script defer src="./assets/gallery.js"></script>
</head>
<body class="gallery-terminal">
  <a class="skip-link" href="#content">跳到正文</a>

  <header class="gallery-topbar" aria-label="画廊导航">
    <a class="gallery-logo" href="./index.html">ZHECAI <em>GALLERY</em></a>
    <nav class="gallery-nav" aria-label="站点">
      <a href="./index.html">ARCHIVE</a>
      <a href="./gallery.html" aria-current="page">GALLERY</a>
    </nav>
    <div class="gallery-status" aria-label="系统状态">
      <span class="live-dot" aria-hidden="true"></span>
      <span>LOCAL DISPLAY</span>
    </div>
  </header>

  <main id="content" class="gallery-shell" data-gallery>
    <section class="gallery-alert" aria-label="画廊状态">
      <span class="gallery-alert-badge">CRT</span>
      <span class="gallery-alert-text">VISUAL ARCHIVE / STATIC DISPLAY</span>
      <span class="gallery-clock" data-gallery-clock>--:--:--</span>
    </section>

    <section class="gallery-hero crt-monitor" aria-labelledby="gallery-title">
      <div class="gallery-hero-copy terminal-text">
        <p class="gallery-kicker">BOOT: VISUAL ARCHIVE</p>
        <h1 id="gallery-title">画廊</h1>
        <p>VISUAL ARCHIVE</p>
      </div>
      <dl class="gallery-meter" aria-label="画廊统计">
        <div>
          <dt>ITEMS</dt>
          <dd data-gallery-count>{len(items)}</dd>
        </div>
        <div>
          <dt>MODE</dt>
          <dd>IMAGE + MD</dd>
        </div>
        <div>
          <dt>STATUS</dt>
          <dd>READY</dd>
        </div>
      </dl>
    </section>

    <section class="gallery-control-panel" aria-label="画廊控制">
      <div class="gallery-filter-group" role="group" aria-label="条目筛选">
        <button type="button" class="gallery-button is-active" data-gallery-filter="all" aria-pressed="true">ALL</button>
      </div>
      <p class="gallery-hint"><span class="status-led"></span><span data-gallery-current>READY</span></p>
    </section>

    <section class="gallery-workbench">
      <aside class="gallery-list-panel" aria-labelledby="gallery-list-title">
        <div class="panel-heading">
          <h2 id="gallery-list-title">INDEX</h2>
          <span data-gallery-visible-count>{len(items)} ITEMS</span>
        </div>
        <div class="gallery-list" data-gallery-list></div>
      </aside>

      <article class="gallery-display crt-monitor" aria-live="polite">
        <div class="image-console">
          <div class="console-title">
            <span data-gallery-image-title>IMAGE FEED</span>
            <span class="console-tag" data-gallery-kind>--</span>
          </div>
          <figure class="gallery-figure">
            <img data-gallery-image alt="" src="">
            <figcaption data-gallery-caption hidden></figcaption>
          </figure>
        </div>

        <div class="doc-console">
          <div class="console-title">
            <span data-gallery-doc-title>MARKDOWN RENDER</span>
            <a data-gallery-md-link href="#" target="_blank" rel="noopener">OPEN .MD</a>
          </div>
          <div class="markdown-body" data-gallery-doc>
            <p class="loading-line">READY<span class="blinking-cursor" aria-hidden="true"></span></p>
          </div>
        </div>
      </article>
    </section>
  </main>
</body>
</html>
"""


def clean_stale_pages(categories: list[Category]) -> None:
    OBJECT_DIR.mkdir(exist_ok=True)
    valid = {category.output_name for category in categories}
    for path in OBJECT_DIR.glob("*.html"):
        if path.name not in valid:
            path.unlink()


def write_site(categories: list[Category]) -> None:
    OBJECT_DIR.mkdir(exist_ok=True)
    ASSETS_DIR.mkdir(exist_ok=True)
    clean_stale_pages(categories)

    (ROOT / "index.html").write_text(render_home(categories), encoding="utf-8")
    (ROOT / "gallery.html").write_text(render_gallery_page(collect_gallery_items()), encoding="utf-8")
    for category in categories:
        (OBJECT_DIR / category.output_name).write_text(
            render_archive_page(category, categories),
            encoding="utf-8",
        )


def main() -> None:
    categories = collect_categories()
    write_site(categories)


if __name__ == "__main__":
    main()
