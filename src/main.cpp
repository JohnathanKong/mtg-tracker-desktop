#define NOMINMAX
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#include <shlobj.h>
#include <gdiplus.h>
#include <algorithm>
#include <array>
#include <cwctype>
#include <memory>
#include <string>
#include <vector>

using namespace Gdiplus;
struct Counter { const wchar_t* id; const wchar_t* label; const wchar_t* category; };
static const std::array<Counter,22> counters = {{
 {L"life",L"Life total",L"Universal"},
 {L"poison",L"Poison counters",L"Universal"},
 {L"rad",L"Rad counters",L"Universal"},
 {L"commander_damage",L"Commander damage received",L"Universal"},
 {L"commander_casts",L"Commander casts / tax",L"Universal"},
 {L"commander_deaths",L"Commander deaths",L"Universal"},
 {L"energy",L"Energy counters",L"Deck mechanic"},
 {L"experience",L"Experience counters",L"Deck mechanic"},
 {L"tickets",L"Ticket counters",L"Deck mechanic"},
 {L"storm",L"Storm count",L"Deck mechanic"},
 {L"speed",L"Speed",L"Deck mechanic"},
 {L"ring",L"Ring temptation",L"Deck mechanic"},
 {L"dungeon",L"Dungeon progress",L"Deck mechanic"},
 {L"monarch",L"Monarch",L"Game state"},
 {L"initiative",L"Initiative",L"Game state"},
 {L"citys_blessing",L"City's blessing",L"Game state"},
 {L"day_night",L"Day / night",L"Game state"},
 {L"emblems",L"Emblems",L"Game state"},
 {L"mana_pool",L"Mana pool",L"Optional"},
 {L"turn",L"Turn number",L"Optional"},
 {L"custom_1",L"Custom counter 1",L"Optional"},
 {L"custom_2",L"Custom counter 2",L"Optional"}
}};
struct Deck {
 std::wstring id, name, commander, image;
 std::vector<std::wstring> enabled;
};
static HINSTANCE instance;
static HWND mainWindow, deckList, nameEdit, commanderEdit, counterList, importButton, saveButton, deleteButton, messageText;
static HWND titleLabel, imageLabel, nameLabel, commanderLabel, countersLabel, addButton;
static HFONT normalFont, titleFont, smallFont;
static std::vector<Deck> decks;
static std::wstring storage, ini;
static int selected=-1;
static bool busy=false;
static ULONG_PTR gdiToken;

static std::wstring value(HWND h) {
 int n=GetWindowTextLengthW(h);
 std::wstring s(size_t(n)+1,L'\0');
 GetWindowTextW(h,s.data(),n+1);
 s.resize(n);
 return s;
}
static std::vector<std::wstring> split(const std::wstring& text,wchar_t c) {
 std::vector<std::wstring> out;
 size_t pos=0;
 while(pos<text.size()) {
  size_t end=text.find(c,pos);
  std::wstring part=text.substr(pos,end==std::wstring::npos?std::wstring::npos:end-pos);
  if(!part.empty()) out.push_back(part);
  if(end==std::wstring::npos) break;
  pos=end+1;
 }
 return out;
}
static std::wstring combine(const std::vector<std::wstring>& parts) {
 std::wstring s;
 for(const auto& p:parts) {if(!s.empty()) s+=L',';s+=p;}
 return s;
}
static std::wstring read(const std::wstring& sec,const wchar_t* key,const wchar_t* fallback=L"") {
 std::vector<wchar_t> b(32768);
 GetPrivateProfileStringW(sec.c_str(),key,fallback,b.data(),DWORD(b.size()),ini.c_str());
 return b.data();
}
static void write(const std::wstring& sec,const wchar_t* key,const std::wstring& v) {
 WritePrivateProfileStringW(sec.c_str(),key,v.c_str(),ini.c_str());
}
static std::wstring makeId() {
 GUID guid{};
 if(SUCCEEDED(CoCreateGuid(&guid))) {
  wchar_t buffer[64]{};
  StringFromGUID2(guid,buffer,64);
  std::wstring s=buffer;
  s.erase(std::remove_if(s.begin(),s.end(),[](wchar_t c){return c==L'{'||c==L'}'||c==L'-';}),s.end());
  return s;
 }
 return std::to_wstring(GetTickCount64());
}
static bool has(const Deck& d,const wchar_t* counter) {
 return std::find(d.enabled.begin(),d.enabled.end(),counter)!=d.enabled.end();
}
static void collect() {
 if(busy||selected<0||selected>=int(decks.size())) return;
 auto& d=decks[selected];
 d.name=value(nameEdit);
 d.commander=value(commanderEdit);
 d.enabled.clear();
 for(int i=0;i<int(counters.size());++i)
  if(ListView_GetCheckState(counterList,i)) d.enabled.push_back(counters[i].id);
}
static void save() {
 collect();
 std::vector<std::wstring> ids;
 for(const auto& d:decks) {
  ids.push_back(d.id);
  const std::wstring section=L"deck_"+d.id;
  write(section,L"name",d.name);
  write(section,L"commander",d.commander);
  write(section,L"image",d.image);
  write(section,L"counters",combine(d.enabled));
 }
 write(L"decks",L"ids",combine(ids));
 write(L"settings",L"format",L"1");
 if(messageText) SetWindowTextW(messageText,L"Saved locally");
}
static void load() {
 for(const auto& id:split(read(L"decks",L"ids"),L',')) {
  Deck d;
  d.id=id;
  const auto section=L"deck_"+id;
  d.name=read(section,L"name",L"Untitled deck");
  d.commander=read(section,L"commander");
  d.image=read(section,L"image");
  d.enabled=split(read(section,L"counters"),L',');
  decks.push_back(std::move(d));
 }
}
static void listRefresh() {
 SendMessageW(deckList,LB_RESETCONTENT,0,0);
 for(const auto& d:decks) {
  std::wstring text=d.name.empty()?L"Untitled deck":d.name;
  SendMessageW(deckList,LB_ADDSTRING,0,LPARAM(text.c_str()));
 }
 if(selected>=0) SendMessageW(deckList,LB_SETCURSEL,selected,0);
}
static void editorRefresh() {
 busy=true;
 const bool valid=selected>=0&&selected<int(decks.size());
 SetWindowTextW(nameEdit,valid?decks[selected].name.c_str():L"");
 SetWindowTextW(commanderEdit,valid?decks[selected].commander.c_str():L"");
 for(int i=0;i<int(counters.size());++i)
  ListView_SetCheckState(counterList,i,valid&&has(decks[selected],counters[i].id));
 for(HWND h:{nameEdit,commanderEdit,counterList,importButton,saveButton,deleteButton}) EnableWindow(h,valid);
 SetWindowTextW(messageText,valid?L"Edit your profile and click Save":L"Create a deck to get started");
 busy=false;
 InvalidateRect(mainWindow,nullptr,TRUE);
}
static void addDeck() {
 if(selected>=0) save();
 Deck d;
 d.id=makeId();
 d.name=L"New deck";
 d.enabled={L"life",L"poison",L"rad",L"commander_damage",L"commander_casts",L"commander_deaths"};
 decks.push_back(std::move(d));
 selected=int(decks.size())-1;
 listRefresh();
 editorRefresh();
 save();
 SetFocus(nameEdit);
 SendMessageW(nameEdit,EM_SETSEL,0,-1);
}
static void removeDeck() {
 if(selected<0) return;
 if(MessageBoxW(mainWindow,L"Delete this deck profile? Imported artwork is kept.",L"Delete deck",
   MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2)!=IDYES) return;
 const std::wstring section=L"deck_"+decks[selected].id;
 decks.erase(decks.begin()+selected);
 WritePrivateProfileStringW(section.c_str(),nullptr,nullptr,ini.c_str());
 selected=decks.empty()?-1:std::min(selected,int(decks.size())-1);
 listRefresh();
 editorRefresh();
 save();
}
static void importArtwork() {
 if(selected<0) return;
 wchar_t path[32768]{};
 OPENFILENAMEW dialog{};
 dialog.lStructSize=sizeof(dialog);
 dialog.hwndOwner=mainWindow;
 dialog.lpstrFile=path;
 dialog.nMaxFile=32768;
 dialog.lpstrFilter=L"Image files (*.png;*.jpg;*.jpeg;*.bmp;*.gif)\0*.png;*.jpg;*.jpeg;*.bmp;*.gif\0All files (*.*)\0*.*\0";
 dialog.Flags=OFN_FILEMUSTEXIST|OFN_PATHMUSTEXIST;
 if(!GetOpenFileNameW(&dialog)) return;
 std::unique_ptr<Image> img(Image::FromFile(path));
 if(!img||img->GetLastStatus()!=Ok) {
  MessageBoxW(mainWindow,L"The selected image could not be opened.",L"Image error",MB_OK|MB_ICONERROR);
  return;
 }
 std::wstring source(path);
 size_t dot=source.find_last_of(L'.');
 std::wstring ext=dot==std::wstring::npos?L".png":source.substr(dot);
 std::transform(ext.begin(),ext.end(),ext.begin(),[](wchar_t c){return std::towlower(c);});
 if(ext!=L".png"&&ext!=L".jpg"&&ext!=L".jpeg"&&ext!=L".bmp"&&ext!=L".gif") {
  MessageBoxW(mainWindow,L"Choose a PNG, JPEG, BMP, or GIF file.",L"Image type",MB_OK|MB_ICONERROR);
  return;
 }
 std::wstring destination=storage+L"\\images\\"+decks[selected].id+ext;
 img.reset();
 if(!CopyFileW(path,destination.c_str(),FALSE)) {
  MessageBoxW(mainWindow,L"Unable to copy artwork into local storage.",L"Import error",MB_OK|MB_ICONERROR);
  return;
 }
 decks[selected].image=destination;
 save();
 InvalidateRect(mainWindow,nullptr,TRUE);
}
static HWND control(const wchar_t* cls,const wchar_t* label,DWORD style,int id) {
 HWND h=CreateWindowExW(0,cls,label,style|WS_CHILD|WS_VISIBLE,0,0,1,1,mainWindow,
  reinterpret_cast<HMENU>(INT_PTR(id)),instance,nullptr);
 SendMessageW(h,WM_SETFONT,WPARAM(normalFont),TRUE);
 return h;
}
static void place(HWND h,int x,int y,int w,int height) {
 MoveWindow(h,x,y,std::max(1,w),std::max(1,height),TRUE);
}
static void resize(HWND w) {
 RECT rc{};GetClientRect(w,&rc);
 int width=rc.right,height=rc.bottom;
 int left=std::max(190,std::min(300,int(width)/3));
 int rightX=left+54,rightW=std::max(200,width-rightX-24);
 place(titleLabel,24,17,width-48,42);
 place(addButton,24,78,left,36);
 place(deckList,24,125,left,std::max(80,height-322));
 place(imageLabel,24,height-185,left,24);
 place(nameLabel,rightX,83,rightW,22);
 place(nameEdit,rightX,108,rightW,31);
 place(commanderLabel,rightX,148,rightW,22);
 place(commanderEdit,rightX,173,rightW,31);
 place(importButton,rightX,219,145,35);
 place(saveButton,rightX+155,219,80,35);
 place(deleteButton,rightX+245,219,118,35);
 place(countersLabel,rightX,274,rightW,22);
 place(counterList,rightX,306,rightW,std::max(80,height-357));
 place(messageText,24,height-36,width-48,22);
 ListView_SetColumnWidth(counterList,0,std::max(110,rightW-155));
 ListView_SetColumnWidth(counterList,1,150);
}
static void drawArtwork(HDC hdc) {
 RECT client{};GetClientRect(mainWindow,&client);
 const int left=std::max(190,std::min(300,int(client.right)/3));
 const Rect area(24,client.bottom-158,left,110);
 Graphics g(hdc);
 SolidBrush fill(Color(255,232,237,246));
 g.FillRectangle(&fill,area);
 if(selected<0||decks[selected].image.empty()) return;
 std::unique_ptr<Image> image(Image::FromFile(decks[selected].image.c_str()));
 if(!image||image->GetLastStatus()!=Ok||!image->GetWidth()||!image->GetHeight()) return;
 double scale=std::min(double(area.Width)/image->GetWidth(),double(area.Height)/image->GetHeight());
 int iw=int(image->GetWidth()*scale),ih=int(image->GetHeight()*scale);
 g.SetInterpolationMode(InterpolationModeHighQualityBicubic);
 g.DrawImage(image.get(),area.X+(area.Width-iw)/2,area.Y+(area.Height-ih)/2,iw,ih);
}
static LRESULT CALLBACK procedure(HWND w,UINT msg,WPARAM wp,LPARAM lp) {
 switch(msg) {
 case WM_CREATE: {
  normalFont=CreateFontW(-17,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,
    CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,DEFAULT_PITCH,L"Segoe UI");
  titleFont=CreateFontW(-30,0,0,0,FW_SEMIBOLD,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,
    CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,DEFAULT_PITCH,L"Segoe UI");
  smallFont=CreateFontW(-15,0,0,0,FW_NORMAL,0,0,0,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,
    CLIP_DEFAULT_PRECIS,CLEARTYPE_QUALITY,DEFAULT_PITCH,L"Segoe UI");
  titleLabel=control(L"STATIC",L"MTG Tracker  /  Deck Library",SS_LEFT,100);
  SendMessageW(titleLabel,WM_SETFONT,WPARAM(titleFont),TRUE);
  addButton=control(L"BUTTON",L"+  New deck",BS_PUSHBUTTON,101);
  deckList=control(L"LISTBOX",L"",LBS_NOTIFY|WS_BORDER|WS_VSCROLL,102);
  imageLabel=control(L"STATIC",L"DECK ARTWORK",SS_LEFT,103);
  SendMessageW(imageLabel,WM_SETFONT,WPARAM(smallFont),TRUE);
  nameLabel=control(L"STATIC",L"Deck name",SS_LEFT,104);
  nameEdit=control(L"EDIT",L"",ES_AUTOHSCROLL|WS_BORDER|WS_TABSTOP,105);
  commanderLabel=control(L"STATIC",L"Commander name",SS_LEFT,106);
  commanderEdit=control(L"EDIT",L"",ES_AUTOHSCROLL|WS_BORDER|WS_TABSTOP,107);
  importButton=control(L"BUTTON",L"Import image...",BS_PUSHBUTTON,108);
  saveButton=control(L"BUTTON",L"Save",BS_PUSHBUTTON,109);
  deleteButton=control(L"BUTTON",L"Delete deck",BS_PUSHBUTTON,110);
  countersLabel=control(L"STATIC",L"COUNTERS & TRACKERS  (check what this deck needs)",SS_LEFT,111);
  SendMessageW(countersLabel,WM_SETFONT,WPARAM(smallFont),TRUE);
  counterList=CreateWindowExW(WS_EX_CLIENTEDGE,WC_LISTVIEWW,L"",WS_VISIBLE|WS_CHILD|
   LVS_REPORT|LVS_SHOWSELALWAYS|LVS_SINGLESEL|WS_TABSTOP,0,0,100,100,w,
   reinterpret_cast<HMENU>(INT_PTR(112)),instance,nullptr);
  SendMessageW(counterList,WM_SETFONT,WPARAM(normalFont),TRUE);
  ListView_SetExtendedListViewStyle(counterList,LVS_EX_CHECKBOXES|LVS_EX_FULLROWSELECT|LVS_EX_DOUBLEBUFFER);
  LVCOLUMNW col{};col.mask=LVCF_TEXT|LVCF_WIDTH;col.cx=200;
  col.pszText=const_cast<wchar_t*>(L"Tracker");ListView_InsertColumn(counterList,0,&col);
  col.cx=140;col.pszText=const_cast<wchar_t*>(L"Category");ListView_InsertColumn(counterList,1,&col);
  for(int i=0;i<int(counters.size());++i) {
   LVITEMW row{};row.mask=LVIF_TEXT;row.iItem=i;
   row.pszText=const_cast<wchar_t*>(counters[i].label);
   ListView_InsertItem(counterList,&row);
   ListView_SetItemText(counterList,i,1,const_cast<wchar_t*>(counters[i].category));
  }
  messageText=control(L"STATIC",L"",SS_LEFT,113);
  SendMessageW(messageText,WM_SETFONT,WPARAM(smallFont),TRUE);
  load();selected=decks.empty()?-1:0;listRefresh();editorRefresh();
  return 0;
 }
 case WM_SIZE: resize(w);return 0;
 case WM_COMMAND: {
  int id=LOWORD(wp),event=HIWORD(wp);
  if(id==101&&event==BN_CLICKED) addDeck();
  if(id==102&&event==LBN_SELCHANGE&&!busy) {
   int next=int(SendMessageW(deckList,LB_GETCURSEL,0,0));
   if(next!=selected) {save();selected=next;editorRefresh();}
  }
  if(id==108&&event==BN_CLICKED) importArtwork();
  if(id==109&&event==BN_CLICKED) {save();listRefresh();}
  if(id==110&&event==BN_CLICKED) removeDeck();
  if((id==105||id==107)&&event==EN_CHANGE&&!busy&&selected>=0) {
   decks[selected].name=value(nameEdit);
   decks[selected].commander=value(commanderEdit);
   if(id==105) listRefresh();
   SetWindowTextW(messageText,L"Unsaved edits (Save or select another deck)");
  }
  return 0;
 }
 case WM_NOTIFY:
  if(reinterpret_cast<NMHDR*>(lp)->idFrom==112&&
     reinterpret_cast<NMHDR*>(lp)->code==LVN_ITEMCHANGED&&!busy&&selected>=0)
    SetWindowTextW(messageText,L"Unsaved edits (Save or select another deck)");
  return 0;
 case WM_PAINT: {
  PAINTSTRUCT ps{};HDC dc=BeginPaint(w,&ps);drawArtwork(dc);EndPaint(w,&ps);
  return 0;
 }
 case WM_CLOSE: save();DestroyWindow(w);return 0;
 case WM_DESTROY:
  DeleteObject(normalFont);DeleteObject(titleFont);DeleteObject(smallFont);
  PostQuitMessage(0);return 0;
 }
 return DefWindowProcW(w,msg,wp,lp);
}
int WINAPI wWinMain(HINSTANCE app,HINSTANCE,LPWSTR,int show) {
 instance=app;
 INITCOMMONCONTROLSEX cc{};cc.dwSize=sizeof(cc);cc.dwICC=ICC_LISTVIEW_CLASSES;
 InitCommonControlsEx(&cc);
 GdiplusStartupInput input;GdiplusStartup(&gdiToken,&input,nullptr);
 wchar_t base[MAX_PATH]{};
 if(FAILED(SHGetFolderPathW(nullptr,CSIDL_LOCAL_APPDATA|CSIDL_FLAG_CREATE,nullptr,SHGFP_TYPE_CURRENT,base)))return 1;
 storage=std::wstring(base)+L"\\MTGTrackerDesktop";
 CreateDirectoryW(storage.c_str(),nullptr);
 CreateDirectoryW((storage+L"\\images").c_str(),nullptr);
 ini=storage+L"\\decks.ini";
 if(GetFileAttributesW(ini.c_str())==INVALID_FILE_ATTRIBUTES) {
  HANDLE file=CreateFileW(ini.c_str(),GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,nullptr);
  if(file!=INVALID_HANDLE_VALUE) {
   WORD bom=0xFEFF;DWORD written=0;WriteFile(file,&bom,sizeof(bom),&written,nullptr);CloseHandle(file);
  }
 }
 WNDCLASSW cls{};cls.hInstance=app;cls.lpfnWndProc=procedure;
 cls.lpszClassName=L"MTGTrackerDesktopWindow";cls.hCursor=LoadCursorW(nullptr,IDC_ARROW);
 cls.hbrBackground=HBRUSH(COLOR_WINDOW+1);cls.hIcon=LoadIconW(nullptr,IDI_APPLICATION);
 RegisterClassW(&cls);
 mainWindow=CreateWindowExW(0,cls.lpszClassName,L"MTG Tracker Desktop",WS_OVERLAPPEDWINDOW,
   CW_USEDEFAULT,CW_USEDEFAULT,990,790,nullptr,nullptr,app,nullptr);
 if(!mainWindow){GdiplusShutdown(gdiToken);return 2;}
 ShowWindow(mainWindow,show);UpdateWindow(mainWindow);
 MSG event{};
 while(GetMessageW(&event,nullptr,0,0)>0) {TranslateMessage(&event);DispatchMessageW(&event);}
 GdiplusShutdown(gdiToken);
 return int(event.wParam);
}
