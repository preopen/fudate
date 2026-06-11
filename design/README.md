# PrepFlow — 設計ドラフト（design）

軽量版PrepFlow（コース・予約主体の中〜高級飲食店向け 仕込み管理SaaS）の検討用ドラフト一式。

## 成果物
| ファイル | 内容 |
|---|---|
| `competitive-positioning.html` / `.png` | 競合ポジショニング図（V-Manage / カミナシ / PrepFlow）。2軸マップ＋機能マップ比較表 |
| `p0-wireframe-todaytask.html` / `.png` | P0ワイヤーフレーム：今日のタスク（仕込みボード）＋手順メディア添付。番号①〜⑦は要件定義v0.2のFRに対応 |

HTMLは自己完結（元プロトタイプと同じデザイントークン）。ブラウザで直接開けます。

## PNGの再生成
```bash
cd design
npm i            # puppeteer を取得（node_modules はコミット対象外）
node render.mjs  # competitive-positioning.png / p0-wireframe-todaytask.png を生成
```
