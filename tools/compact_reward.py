from pathlib import Path
p=Path('lib/features/daily_reward/reward_screen.dart');s=p.read_text(encoding='utf-8')
a=s.index('          CreamPanel(');b=s.index('          const SizedBox(height: 12),',a)
s=s[:a]+'''          CreamPanel(padding: const EdgeInsets.all(8), child: LayoutBuilder(
            builder: (context,b) => Wrap(spacing:8,runSpacing:8,alignment:WrapAlignment.center,
              children: List.generate(7,(i)=>Container(
                width: i==6 ? b.maxWidth : (b.maxWidth-16)/3,
                height: i==6 ? 52 : 82,
                decoration:BoxDecoration(color:i==activeDay ? const Color(0xffd5f2bb) : const Color(0xfffff4e3),
                  borderRadius:BorderRadius.circular(14),border:Border.all(color:i==activeDay?green:Colors.white,width:2)),
                child:Center(child: i==6 ? Text('🎁  7. ${tr(ref,'Gün','Day')}  •  150',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)) :
                  Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                    Text('${i+1}. ${tr(ref,'Gün','Day')}',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
                    Text('🪙 ${dailyRewards[i]}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:21)),
                    if(i==activeDay) Text(claimable?tr(ref,'Bugün','Today'):tr(ref,'Alındı ✓','Claimed ✓'),style:const TextStyle(fontSize:11,color:green)),
                  ])),
              )),
            ),
          )),
'''+s[b:]
p.write_text(s,encoding='utf-8')
