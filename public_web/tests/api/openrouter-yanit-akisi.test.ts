import { describe, expect, it } from "vitest";
import { openrouterYanitiniOku } from "@/lib/openrouterYanitAkisi";
const frame=(data:unknown)=>`data: ${JSON.stringify(data)}\n\n`;
const response=(text:string)=>new Response(text,{headers:{"content-type":"text/event-stream"}});
describe("OpenRouter yanıt akışı",()=>{
 it("yorum/keepalive ve parçalanmış JSON birleştirilir; son usage korunur",async()=>{
  const text=': OPENROUTER PROCESSING\n\n'+frame({id:"gen-test",model:"minimax",choices:[{index:0,delta:{content:'{"satirlar":'},finish_reason:null}]})+
   frame({choices:[{index:0,delta:{content:'[]}'},finish_reason:"stop"}]})+
   frame({choices:[{index:0,delta:{},finish_reason:"stop"}],usage:{cost:0.01}})+'data: [DONE]\n\n';
  const r=await openrouterYanitiniOku(response(text));
  expect(r?.choices?.[0].message.content).toBe('{"satirlar":[]}');expect(r?.usage?.cost).toBe(0.01);expect(r?.id).toBe("gen-test");
 });
 it("UTF-8 ve CRLF sınırları byte parçasında bölünebilir",async()=>{
  const text=(frame({choices:[{index:0,delta:{content:'{"ad":"ÜLKER"}'},finish_reason:"stop"}]})+'data: [DONE]\n\n').replaceAll('\n','\r\n');
  const bytes=new TextEncoder().encode(text);
  const stream=new ReadableStream<Uint8Array>({start(c){for(const b of bytes)c.enqueue(new Uint8Array([b]));c.close();}});
  const r=await openrouterYanitiniOku(new Response(stream,{headers:{"content-type":"text/event-stream"}}));
  expect(r?.choices?.[0].message.content).toBe('{"ad":"ÜLKER"}');
 });
 it("HTTP 200 olsa da SSE error başarılı sayılmaz",async()=>{
  await expect(openrouterYanitiniOku(response(frame({error:{code:502},choices:[{finish_reason:"error"}]})))).rejects.toThrow("OKUYUCU_CEVAP_VERMEDI");
 });
 it("gerçek araştırmada görülen model 404 hatası açıkça ayrılır",async()=>{
  await expect(openrouterYanitiniOku(response(frame({error:{code:404,message:"Model call failed: upstream returned 404"}})))).rejects.toThrow("OKUYUCU_MODEL_BULUNAMADI");
 });
 it("DONE eksikse tamamlanmış JSON bile reddedilir",async()=>{
  await expect(openrouterYanitiniOku(response(frame({choices:[{delta:{content:'{"satirlar":[]}'},finish_reason:"stop"}]})))).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");
 });
 it("finish_reason eksikse reddedilir",async()=>{
  await expect(openrouterYanitiniOku(response('data: [DONE]\n\n'))).rejects.toThrow("OKUYUCU_EKSIK_CEVAP");
 });
 it("JSON modunda gelen hata gövdesi korunur",async()=>{
  const r=await openrouterYanitiniOku(new Response('{"error":{"code":402}}',{status:402,headers:{"content-type":"application/json"}}));
  expect(r?.error?.code).toBe(402);
 });
 it("length ve bekleyen tool_calls nihai okuyucuya aynen geçer",async()=>{
  const r=await openrouterYanitiniOku(response(frame({choices:[{delta:{tool_calls:[{id:"tool"}]},finish_reason:"length"}]})+'data: [DONE]\n\n'));
  expect(r?.choices?.[0].finish_reason).toBe("length");expect(r?.choices?.[0].message.tool_calls).toHaveLength(1);
 });
});
