// Flutter web demosunda ekran görüntüleri (README için).
const { chromium } = require('playwright');

const OUT = '../ci-out/shots';
const wait = (p, ms) => p.waitForTimeout(ms);

async function tap(p, name, { exact = true } = {}) {
  const tries = [
    () => p.getByRole('button', { name, exact }),
    () => p.getByRole('tab', { name, exact }),
    () => p.getByRole('link', { name, exact }),
    () => p.getByText(name, { exact }),
    () => p.getByLabel(name, { exact }),
  ];
  for (const t of tries) {
    const loc = t().first();
    if (await loc.count()) {
      try {
        await loc.click({ timeout: 3000 });
        await wait(p, 900);
        console.log('ok', name);
        return true;
      } catch (e) { /* sonraki yöntem */ }
    }
  }
  console.log('BULUNAMADI', name);
  return false;
}

async function scroll(p, dy) {
  const v = p.viewportSize();
  await p.mouse.move(v.width / 2, v.height / 2);
  await p.mouse.wheel(0, dy);
  await wait(p, 700);
}

async function shot(p, name) {
  await wait(p, 900);
  await p.screenshot({ path: `${OUT}/${name}.png` });
  console.log('shot', name);
}

async function session(browser, size, prefix) {
  const ctx = await browser.newContext({
    viewport: size, deviceScaleFactor: 2, locale: 'tr-TR', colorScheme: 'light',
  });
  const p = await ctx.newPage();
  p.on('console', (m) => { if (m.type() === 'error') console.log('console', m.text()); });
  await p.goto('http://localhost:8080/', { waitUntil: 'networkidle' });
  await wait(p, 4000);
  // Flutter erişilebilirlik ağacını aç (metinler DOM'a gelsin).
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await wait(p, 1500);
  return p;
}

(async () => {
  const browser = await chromium.launch();
  const p = await session(browser, { width: 390, height: 844 }, 'm');
  await shot(p, '01-giris');
  await tap(p, 'Demo hesabıyla dene');
  await wait(p, 1500);
  await shot(p, '02-rutin');
  await scroll(p, 700);
  await shot(p, '03-rutin-uyarilar');
  await scroll(p, -2000);
  await tap(p, 'Hatırlatmalar', { exact: false });
  await shot(p, '04-hatirlatmalar');
  await tap(p, 'Geri');
  await tap(p, 'Ürünler');
  await shot(p, '05-urunler');
  await tap(p, 'Retinol %0.3 Gece Serumu', { exact: false });
  await scroll(p, 600);
  await shot(p, '06-urun-analiz');
  await scroll(p, 600);
  await shot(p, '07-urun-analiz-2');
  await tap(p, 'Geri');
  await tap(p, 'Koleksiyon');
  await shot(p, '08-koleksiyon');
  await tap(p, 'Bitirdiklerim', { exact: false });
  await shot(p, '08b-bitirdiklerim');
  await tap(p, 'Memnun kaldıklarım', { exact: false });
  await shot(p, '08c-memnun');
  await tap(p, 'Profil');
  await shot(p, '09-profil');
  await scroll(p, 500);
  await shot(p, '09b-profil-istatistik');

  // Ürün önerisi → onay kuyruğu (fotoğraf zorunlu; seçici sahte dosyayla).
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
  p.on('filechooser', (fc) => fc.setFiles({ name: 'urun.png', mimeType: 'image/png', buffer: png }));
  await tap(p, 'Ürünler');
  const box = p.getByRole('textbox').first();
  await box.click(); await box.fill('Nem Dengesi Temizleyicisi'); await wait(p, 900);
  await tap(p, 'Bu ürünü sisteme ekle', { exact: false });
  const brand = p.getByRole('textbox').nth(1);
  if (await brand.count()) { await brand.click(); await brand.fill('Lumen Lab'); await wait(p, 500); }
  await tap(p, 'Kategori seçin');
  await tap(p, 'Temizleyici');
  await tap(p, 'Hassas Cilt');
  await tap(p, 'Devam Et');
  const ing = p.getByRole('textbox').first();
  await ing.click(); await ing.fill('Aqua, Glycerin, Panthenol, Allantoin'); await wait(p, 600);
  await tap(p, 'Devam Et');
  await tap(p, 'Fotoğraf Seç', { exact: false });
  await wait(p, 1500);
  await shot(p, '11-oneri-foto');
  await tap(p, 'İncelemeye Gönder');
  await tap(p, 'Onay ekranını aç');
  await shot(p, '12-onay-kuyrugu');
  await tap(p, 'Düzenle');
  await shot(p, '13-duzenle-onayla');
  await tap(p, 'Geri');
  await tap(p, 'Yinelenen');
  await shot(p, '14-yinelenen-sec');

  const d = await session(browser, { width: 1280, height: 800 }, 'd');
  await tap(d, 'Demo hesabıyla dene');
  await tap(d, 'Ürünler');
  await shot(d, '10-masaustu-urunler');
  await browser.close();
})();
