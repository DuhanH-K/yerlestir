from pathlib import Path
p=Path('lib/features/home/home_screen.dart')
s=p.read_text(encoding='utf-8'); tail=s[s.index('class _ModeCard'):].replace('height: 145','height: 86')
head='''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/game_ui.dart';
import '../../core/services/feedback_service.dart';
import '../progress/progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    return GameShell(back:false, child: LayoutBuilder(builder:(context,b) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children:[
        SizedBox(height: b.maxHeight > 650 ? 100 : 60, child: const Center(child: GameTitle('Yerleştir!', size: 48))),
        const SizedBox(height: 10),
        Row(children:[for(var i=0;i<3;i++) ...[
          if(i>0) const SizedBox(width:8),
          Expanded(child:_ModeCard(index:i, selected:selected==i, onTap:()=>setState(()=>selected=i),
            title:[tr(ref,'Klasik','Classic'),tr(ref,'Yolculuk','Journey'),tr(ref,'Günlük','Daily')][i],
            subtitle:[tr(ref,'Sınır yok','No limit'),tr(ref,'120 bölüm','120 levels'),tr(ref,'30 hamle','30 moves')][i])),
        ]]),
        Padding(padding: const EdgeInsets.symmetric(vertical:12), child: CreamPanel(
          padding: const EdgeInsets.symmetric(horizontal:10,vertical:8),
          child: Text([
            tr(ref,'Süre sınırı yok. Yer kaldıkça oyna, rekorunu geliştir.','No timer. Keep placing pieces and beat your best.'),
            tr(ref,'Hedef puana ulaş, yıldız kazan ve yeni bölümleri aç.','Reach the target, earn stars and unlock levels.'),
            tr(ref,'Her gün yeni bulmaca: 30 hamlede 800 puan.','A new daily puzzle: 800 points in 30 moves.'),
          ][selected], style:const TextStyle(fontSize:12), textAlign:TextAlign.center))),
        GlossButton(label:tr(ref,'Oyna','Play'),icon:Icons.play_arrow_rounded,color:green,height:58,
          onTap:(){ ref.read(feedbackProvider).music(p.musicEnabled);
            context.push(selected==1?'/journey':'/game/${selected==0?'classic':'daily'}/1'); }),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:GlossButton(label:tr(ref,'Mağaza','Shop'),icon:Icons.storefront_rounded,color:purple,height:56,onTap:()=>context.push('/shop'))),
          const SizedBox(width:10),
          Expanded(child:GlossButton(label:tr(ref,'Günlük Ödül','Daily Reward'),icon:Icons.card_giftcard_rounded,height:56,onTap:()=>context.push('/reward'))),
        ]),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:CreamPanel(padding:const EdgeInsets.all(8),child:Row(children:[
            const Icon(Icons.emoji_events_rounded,color:Colors.amber,size:24),const SizedBox(width:6),
            Expanded(child:Column(children:[Text(tr(ref,'Rekor','Best'),style:const TextStyle(fontSize:11)),
              Text(number(p.highScore),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20))])),
          ]))),
          const SizedBox(width:10),
          Expanded(child:GlossButton(label:tr(ref,'Koleksiyon','Collection'),subtitle:'${p.collectionCount} / 24',height:60,color:purple,onTap:()=>context.push('/collection'))),
        ]),
      ],
    )));
  }
}

'''
p.write_text(head+tail,encoding='utf-8')
# Compact settings, preserving handlers and confirmations.
p=Path('lib/features/settings/settings_screen.dart');s=p.read_text(encoding='utf-8')
s=s.replace('EdgeInsets.all(22)', 'EdgeInsets.all(8)').replace('EdgeInsets.all(20)', 'EdgeInsets.all(8)')
s=s.replace("GameTitle(tr(ref, 'Ayarlar', 'Settings'))", "GameTitle(tr(ref, 'Ayarlar', 'Settings'), size: 32)")
s=s.replace('height: 24','height: 6').replace('height: 17','height: 6')
s=s.replace('CreamPanel(\n', 'CreamPanel(\n            padding: const EdgeInsets.all(4),\n')
s=s.replace('const FooterNote(),','').replace('const Divider(),','')
s=s.replace('ListTile(\n','ListTile(\n                  dense: true,\n                  visualDensity: const VisualDensity(vertical: -4),\n                  minVerticalPadding: 8,\n')
s=s.replace("                  subtitle: Text(\n                    tr(ref, 'Tüm yerel verileri sil', 'Delete all local data'),\n                  ),",'')
s=s.replace('padding: const EdgeInsets.symmetric(vertical: 8)','padding: const EdgeInsets.symmetric(vertical: 0)')
s=s.replace('width: 47','width: 32').replace('height: 47','height: 32').replace('fontSize: 19','fontSize: 16')
s=s.replace('              Text(subtitle, style: const TextStyle(fontSize: 12)),','')
p.write_text(s,encoding='utf-8')
# Compact rewards, no full-width seventh card with extravagant artwork.
p=Path('lib/features/daily_reward/reward_screen.dart');s=p.read_text(encoding='utf-8')
s=s.replace('EdgeInsets.all(22)','EdgeInsets.all(12)').replace("'Günlük\\nÖdül', 'Daily\\nReward'","'Günlük Ödül', 'Daily Reward'")
a=s.index('            subtitle: tr(');b=s.index('            size: 65,',a)
s=s[:a]+s[b:];s=s.replace('size: 65','size: 36')
a=s.index('          const Padding(');b=s.index('          CreamPanel(',a);s=s[:a]+"          const SizedBox(height: 12),\n"+s[b:]
s=s.replace('vertical: 12','vertical: 5').replace('fontSize: 37','fontSize: 24').replace('fontSize: 26','fontSize: 20')
s=s.replace('height: 23','height: 12').replace('height: 22','height: 12').replace('height: 84','height: 56')
s=s.replace('const FooterNote(),','').replace('child: Column(\n                          children:', 'child: Column(\n                          children:')
p.write_text(s,encoding='utf-8')
# Result screen compact enough to leave all actions visible.
p=Path('lib/features/gameplay/presentation/result_screen.dart');s=p.read_text(encoding='utf-8')
s=s.replace('EdgeInsets.all(22)','EdgeInsets.all(10)').replace("            const GameTitle('Yerleştir!', size: 35),",'')
s=s.replace('height: 30','height: 4').replace('size: 53','size: 32').replace('i == 1 ? 95 : 76','i == 1 ? 56 : 48')
s=s.replace('height: 16','height: 8').replace('height: 14','height: 6').replace('height: 22','height: 10').replace('height: 15','height: 6')
s=s.replace('EdgeInsets.all(15)','EdgeInsets.all(6)').replace('fontSize: 30','fontSize: 24').replace('fontSize: 27','fontSize: 20')
s=s.replace('vertical: 6','vertical: 3').replace('height: 85','height: 56').replace('const FooterNote(),','')
s=s.replace("label: tr(ref, 'Tekrar', 'Replay'),", "label: tr(ref, 'Tekrar', 'Replay'),\n                    height: 52,")
s=s.replace("label: tr(ref, 'Ana Sayfa', 'Home'),", "label: tr(ref, 'Ana Sayfa', 'Home'),\n                    height: 52,")
p.write_text(s,encoding='utf-8')
