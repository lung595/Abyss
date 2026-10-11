// Offscreen check of the app-install page (WebKitGTK through gjs): console errors, overlaps,
// overflow, clipped text, target sizes and contrast failures, for every option, theme, mode,
// width, asked action and device name. Usage: gjs tools/check.js "$PWD/index.html"
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
const out={errs:__errs.slice(),bad:[],cases:0,geo:{}};
const sel='.txt b,.txt p,.step,.cmd,.btn,.t b,.t small,.mini';
const R=e=>e.getBoundingClientRect();
const hit=(a,b)=>a.left<b.right-.5&&b.left<a.right-.5&&a.top<b.bottom-.5&&b.top<a.bottom-.5;
for(const opt of ['a','b','c'])for(const theme of ['stock','sea','wall'])for(const mode of ['dark','light'])for(const w of [580,360])for(const act of ['send','expand','settings'])for(const name of ['short','long']){
 Object.assign(S,{opt,theme,mode,w,act,name,st:'invite'});render();out.cases++;const tag=[opt,theme,mode,w,act,name].join('/');
 for(const box of [...document.querySelectorAll('#all .inv,#sets .set')]){
  const B=R(box),P=box.closest('.pop'),els=[...box.querySelectorAll(sel)];
  if(P){const p=R(P);if(B.left<p.left+15.5||B.right>p.right-15.5||B.top<p.top+15.5||B.bottom>p.bottom-15.5)out.bad.push(tag+' invite past the 16 px margin '+box.className);}
  els.forEach((a,i)=>{const ra=R(a);
   if(ra.right>B.right+.5||ra.left<B.left-.5||ra.bottom>B.bottom+.5)out.bad.push(tag+' overflow '+a.className);
   if(a.matches('.btn')&&ra.height!==44)out.bad.push(tag+' target '+ra.height);
   if(a.matches('.btn')){const s=a.querySelector('span');if(s&&s.scrollWidth>s.clientWidth+1)out.bad.push(tag+' clipped label '+s.textContent);}
   els.slice(i+1).forEach(b=>{if(!a.contains(b)&&!b.contains(a)&&hit(ra,R(b)))out.bad.push(tag+' overlap '+a.className+' x '+b.className);});});}
 if(document.getElementById('contrast').textContent.includes('FAIL'))out.bad.push(tag+' contrast');
 if(theme==='stock'&&mode==='dark'&&act==='send'&&name==='short')out.geo[opt+'/'+w]=[...document.querySelectorAll('#all .inv')].map(e=>Math.round(R(e).width)+'x'+Math.round(R(e).height)).join(' ');
}
out.bad=[...new Set(out.bad.map(b=>b.split('/').slice(0,1)+' '+b.split(' ').slice(1).join(' ')+' @'+b.split(' ')[0]))].slice(0,40);
out.dash=/[\\u2013\\u2014]/.test(document.documentElement.outerHTML);
out.net=/https?:|src=|href=|@import|url\\(/.test(document.documentElement.outerHTML);
return JSON.stringify(out);})()`;
wv.connect('load-changed', (v, ev) => { if (ev !== WebKit.LoadEvent.FINISHED) return;
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 800, () => { wv.evaluate_javascript(CHECK, -1, null, null, null, (o, res) => {
    try { const r = wv.evaluate_javascript_finish(res); print(r.to_string()); } catch (e) { print('EVAL ERROR ' + e.message); }
    loop.quit(); }); return GLib.SOURCE_REMOVE; }); });
wv.load_uri(Gio.File.new_for_path(ARGV[0]).get_uri());
loop.run();
