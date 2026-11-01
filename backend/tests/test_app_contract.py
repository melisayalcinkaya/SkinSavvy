"""Sunucunun kabul ettiği seçenekler uygulamadakiyle aynı mı?

Uygulama seçenekleri app/lib/core/constants/skin_options.dart dosyasında.
Bir tarafta etiket değişip diğerinde değişmezse sunucu modunda kayıtlar
422 ile reddedilir; bu test bunu CI'da yakalar.
"""

import re
from pathlib import Path

import pytest

from app import schemas

DART = Path(__file__).parents[2] / "app" / "lib" / "core" / "constants" / "skin_options.dart"


def dart_list(name: str) -> list[str]:
    source = DART.read_text(encoding="utf-8")
    body = re.search(rf"const {name} = \[(.*?)\];", source, re.S)
    assert body, f"{name} bulunamadı"
    # SkinOption('🌸', 'Karma Cilt') → ikinci dize; düz liste → her dize.
    options = re.findall(r"SkinOption\('[^']*',\s*'([^']*)'", body.group(1))
    return options or re.findall(r"'([^']*)'", body.group(1))


pytestmark = pytest.mark.skipif(not DART.exists(), reason="uygulama kaynağı yok")


@pytest.mark.parametrize(
    ("dart_name", "server"),
    [
        ("skinTypeOptions", schemas.SKIN_TYPES),
        ("concernOptions", schemas.CONCERNS),
        ("intensityOptions", schemas.INTENSITIES),
        ("productCategories", schemas.CATEGORIES),
        ("productSkinTypes", schemas.PRODUCT_SKIN_TYPES),
    ],
)
def test_options_match_app(dart_name, server):
    assert sorted(dart_list(dart_name)) == sorted(server)
