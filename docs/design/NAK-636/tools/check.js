// Offscreen check of the alerts page (WebKitGTK through gjs): console errors, overlaps, overflow,
// target sizes, contrast, em dash and network, for every palette, mode, width, copy and wait.
// Usage: gjs tools/check.js "$PWD/alerts.html"
imports.gi.versions.Gtk = '4.0'; imports.gi.versions.WebKit = '6.0';
const { Gtk, WebKit, GLib, Gio } = imports.gi;
Gtk.init();
const loop = GLib.MainLoop.new(null, false);
const ucm = new WebKit.UserContentManager();
ucm.add_script(new WebKit.UserScript("window.__errs=[];window.addEventListener('error',e=>__errs.push(e.message));", WebKit.UserContentInjectedFrames.TOP_FRAME, WebKit.UserScriptInjectionTime.START, null, null));
const wv = new WebKit.WebView({ user_content_manager: ucm });
const win = new Gtk.Window({ default_width: 1440, default_height: 1400, child: wv });
win.realize();
const CHECK = `(()=>{
document.body.style.width='1392px';const out={errs:__errs.slice(),bad:[],cases:0,minContrast:99,geo:{}};
const R=e=>e.getBoundingClientRect();
const hit=(a,b)=>a.left<b.right-.5&&b.left<a.right-.5&&a.top<b.bottom-.5&&b.top<a.bottom-.5;
const lum=h=>{const c=[1,3,5].map(i=>parseInt(h.substr(i,2),16)/255).map(v=>v<=.03928?v/12.92:Math.pow((v+.055)/1.055,2.4));return .2126*c[0]+.7152*c[1]+.0722*c[2]};
const cr=(a,b)=>{const x=lum(a),y=lum(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05)};
const mix=(f,b,o)=>'#'+[1,3,5].map(i=>Math.round(parseInt(f.substr(i,2),16)*o+parseInt(b.substr(i,2),16)*(1-o)).toString(16).padStart(2,'0')).join('');
for(const pal of ['def','sea','wall'])for(const mode of ['dark','light']){const p=PAL[pal][mode];
 const pairs=[['text/surface',p.text,p.surface,4.5],['variant/surface',p.variant,p.surface,4.5],['text/high',p.text,p.high,4.5],['variant/high',p.variant,p.high,4.5],['onprimary/primary',p.onprimary,p.primary,4.5],['chip',p.primary,mix(p.primary,p.surface,.15),4.5],['primary/surface',p.primary,p.surface,3],['outline/surface',p.outline,p.surface,3],['variant/highest knob',p.variant,p.highest,3],['jelly down/high',p.variant,p.high,3],['jelly up/high',p.primary,p.high,3]];
 for(const q of pairs){const v=cr(q[1],q[2]);out.minContrast=Math.min(out.minContrast,+v.toFixed(2));if(v<q[3])out.bad.push(pal+'/'+mode+' contrast '+q[0]+' '+v.toFixed(2));}
 for(const width of ['wide','narrow'])for(const copy of ['new','old'])for(const wait of [10,30,60,300])for(const icon of ['jf','info']){
  Object.assign(S,{pal,mode,width,copy,wait,icon});draw();out.cases++;const tag=[pal,mode,width,copy,wait,icon].join('/');
  const box=document.querySelector('.panel .body'),B=R(box),els=[...box.querySelectorAll('h3,small,b,.tg,.chip,.cost>span:last-child,.pill,.drop,hr')];
  els.forEach((a,i)=>{const ra=R(a);
   if(ra.right>B.right+.5||ra.left<B.left-.5)out.bad.push(tag+' overflow '+a.className+a.tagName);
   if(!a.matches('.tg,hr')&&a.scrollWidth>a.clientWidth+1&&a.clientWidth)out.bad.push(tag+' clipped '+a.textContent);
   els.slice(i+1).forEach(b=>{if(!a.contains(b)&&!b.contains(a)&&hit(ra,R(b)))out.bad.push(tag+' overlap '+a.textContent.slice(0,20)+' x '+b.textContent.slice(0,20));});});
  box.querySelectorAll('.tg').forEach(t=>{const r=R(t);if(r.height<44||r.width<44)out.bad.push(tag+' target '+r.width+'x'+r.height);});
  document.querySelectorAll('.screen').forEach(s=>{const t=s.querySelector('.toast'),a=R(s),b=R(t);if(b.left<a.left+15.5||b.right>a.right-15.5)out.bad.push(tag+' toast past margin');if(t.scrollWidth>t.clientWidth+1)out.bad.push(tag+' toast clipped');});
  if(pal==='sea'&&mode==='dark'&&copy==='new'&&wait===30&&icon==='jf')out.geo[width]=Math.round(B.width)+'x'+Math.round(B.height);
 }}
out.bad=[...new Set(out.bad.map(b=>b.split(' ').slice(1).join(' ')+' @'+b.split(' ')[0]))].slice(0,30);
const h=document.documentElement.outerHTML;
out.dash=/[\\u2013\\u2014]/.test(h);out.net=/https?:|src=|href=|@import|url\\(/.test(h);
return JSON.stringify(out);})()`;
wv.connect('load-changed', (v, ev) => { if (ev !== WebKit.LoadEvent.FINISHED) return;
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 800, () => { wv.evaluate_javascript(CHECK, -1, null, null, null, (o, res) => {
    try { const r = wv.evaluate_javascript_finish(res); print(r.to_string()); } catch (e) { print('EVAL ERROR ' + e.message); }
    loop.quit(); }); return GLib.SOURCE_REMOVE; }); });
wv.load_uri(Gio.File.new_for_path(ARGV[0]).get_uri());
loop.run();
