# Duitku Sandbox Edge Function

Function ini membuat transaksi Duitku sandbox lewat endpoint:

`https://sandbox.duitku.com/webapi/api/merchant/v2/inquiry`

Set secret sebelum deploy:

```bash
supabase secrets set DUITKU_MERCHANT_CODE=DS31430
supabase secrets set DUITKU_API_KEY=92c9e6d1b62fd868874c560e4c6e00c6
supabase secrets set DUITKU_ENVIRONMENT=sandbox
```

Deploy:

```bash
supabase functions deploy create-duitku-transaction
```

Catatan:

- `DUITKU_MERCHANT_CODE` memakai kode merchant project ThriftIn sandbox: `DS31430`.
- `DUITKU_API_KEY` disimpan sebagai Supabase secret, bukan di Flutter/APK.
- `DUITKU_ENVIRONMENT=sandbox` memakai endpoint sandbox Duitku.
- Jika Duitku membalas `Merchant not found`, pastikan merchant code/API key berasal dari dashboard sandbox. Data production tidak selalu valid di sandbox.
