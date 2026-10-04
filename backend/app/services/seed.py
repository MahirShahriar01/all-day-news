"""Demo content so a fresh installation shows something useful.

The demo links point to well known public websites purely as examples.
Replace them with services you have permission to feature before
publishing your app (see docs/10-play-store-release.md, "Content policy").
"""

from sqlalchemy.orm import Session

from app.models import Category, Site

DEMO = [
    ("News", "news", "newspaper", "#FF7C4DFF", "Breaking news and headlines from around the world.", [
        ("BBC News", "https://www.bbc.com/news", "World news, analysis and video.", "#FFBB1919", "", True),
        ("Reuters", "https://www.reuters.com", "Business, financial and world news.", "#FFFF8000", "", True),
        ("Al Jazeera", "https://www.aljazeera.com", "News from the Middle East and the world.", "#FFFA9000", "", False),
        ("AP News", "https://apnews.com", "Independent global news organisation.", "#FFE21F26", "", False),
        ("The Guardian", "https://www.theguardian.com", "Independent journalism.", "#FF052962", "", False),
    ]),
    ("Live Streaming", "live-streaming", "live_tv", "#FFFF4081", "Live TV, streams and broadcasts.", [
        ("YouTube Live", "https://www.youtube.com/live", "Live streams happening now.", "#FFFF0000", "LIVE", True),
        ("Twitch", "https://www.twitch.tv", "Live streaming for gaming and more.", "#FF9146FF", "LIVE", False),
        ("Al Jazeera Live", "https://www.aljazeera.com/live", "24/7 live news coverage.", "#FFFA9000", "24/7", False),
    ]),
    ("Sports", "sports", "sports_soccer", "#FF00E676", "Scores, fixtures and sports news.", [
        ("ESPN", "https://www.espn.com", "Live scores and sports news.", "#FFD00000", "", True),
        ("BBC Sport", "https://www.bbc.com/sport", "Sport news and live coverage.", "#FFFFD230", "", False),
        ("ESPNcricinfo", "https://www.espncricinfo.com", "Live cricket scores and news.", "#FF03A9F4", "LIVE", False),
    ]),
    ("Technology", "technology", "memory", "#FF00E5FF", "Gadgets, science and the future.", [
        ("The Verge", "https://www.theverge.com", "Technology, science, art and culture.", "#FFE5127D", "", False),
        ("TechCrunch", "https://techcrunch.com", "Startup and technology news.", "#FF0A9E01", "", False),
        ("Ars Technica", "https://arstechnica.com", "Serious technology journalism.", "#FFFF4E00", "", False),
    ]),
    ("Entertainment", "entertainment", "movie", "#FFFFAB40", "Movies, music and celebrity news.", [
        ("IMDb", "https://www.imdb.com", "Movies, TV and celebrities.", "#FFF5C518", "", False),
        ("Rotten Tomatoes", "https://www.rottentomatoes.com", "Movie and TV reviews.", "#FFFA320A", "", False),
    ]),
    ("Education", "education", "school", "#FF69F0AE", "Learn something new every day.", [
        ("Khan Academy", "https://www.khanacademy.org", "Free world-class education.", "#FF14BF96", "", False),
        ("Wikipedia", "https://www.wikipedia.org", "The free encyclopedia.", "#FF636466", "", False),
    ]),
    ("Information", "information", "info", "#FF40C4FF", "Weather, reference and useful services.", [
        ("Weather.com", "https://weather.com", "Local and national weather forecasts.", "#FF1F6FB2", "", False),
        ("Time and Date", "https://www.timeanddate.com", "World clock, calendars and time zones.", "#FF2B6CB0", "", False),
    ]),
]


def seed_demo_content(db: Session) -> None:
    if db.query(Category).count() or db.query(Site).count():
        return
    featured_order = 0
    for c_index, (name, slug, icon, color, desc, sites) in enumerate(DEMO):
        cat = Category(name=name, slug=slug, icon_name=icon, color=color, description=desc, sort_order=c_index)
        db.add(cat)
        db.flush()
        for s_index, (title, url, s_desc, accent, badge, featured) in enumerate(sites):
            db.add(
                Site(
                    category_id=cat.id,
                    title=title,
                    url=url,
                    description=s_desc,
                    accent_color=accent,
                    badge=badge,
                    is_featured=featured,
                    featured_order=featured_order if featured else 0,
                    sort_order=s_index,
                    tags=name.lower(),
                )
            )
            if featured:
                featured_order += 1
    db.commit()
