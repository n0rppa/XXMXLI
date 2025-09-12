(function(){
  async function loadConfig(){
    try{
      const res = await fetch('/ad_config.json', {cache: 'no-store'});
      if(!res.ok) return null;
      return await res.json();
    }catch(e){return null}
  }

  function injectAdSense(publisherId, adUnit){
    // Load AdSense script
    if (window.adsbygoogle === undefined) {
      const s = document.createElement('script');
      s.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';
      s.async = true;
      s.setAttribute('data-ad-client', publisherId);
      document.head.appendChild(s);
    }

    const container = document.getElementById('ad-placeholder');
    if(!container) return;

    container.innerHTML = '';
    const ins = document.createElement('ins');
    ins.className = 'adsbygoogle';
    ins.style.display = 'block';
    if(adUnit.format) ins.setAttribute('data-ad-format', adUnit.format);
    // data-ad-slot can be provided in adUnit as slotId in future
    ins.setAttribute('data-ad-client', publisherId);
    container.appendChild(ins);

    try{ (adsbygoogle = window.adsbygoogle || []).push({}); }catch(e){console.warn('adsbygoogle push failed', e)}
  }

  async function init(){
    const cfg = await loadConfig();
    if(!cfg) return;
    if(cfg.provider === 'adsense' && cfg.adsense_publisher_id){
      const unit = (cfg.ad_units && cfg.ad_units[0]) || {format:'auto'};
      injectAdSense(cfg.adsense_publisher_id, unit);
    }
  }

  if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
