create policy "allow authenticated all users" on public.users
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all products" on public.products
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all product_images" on public.product_images
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all user_favorites" on public.user_favorites
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all cart_items" on public.cart_items
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all bids" on public.bids
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all orders" on public.orders
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all notifications" on public.notifications
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all payment_methods" on public.payment_methods
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all help_messages" on public.help_messages
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all chat_rooms" on public.chat_rooms
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all chat_messages" on public.chat_messages
  for all to authenticated using (true) with check (true);

create policy "allow authenticated all reviews" on public.reviews
  for all to authenticated using (true) with check (true);

create policy "allow authenticated product image reads" on storage.objects
  for select to authenticated using (bucket_id = 'product-images');

create policy "allow authenticated product image uploads" on storage.objects
  for insert to authenticated with check (bucket_id = 'product-images');

create policy "allow authenticated product image updates" on storage.objects
  for update to authenticated using (bucket_id = 'product-images') with check (bucket_id = 'product-images');

create policy "allow authenticated product image deletes" on storage.objects
  for delete to authenticated using (bucket_id = 'product-images');

create policy "allow authenticated profile photo reads" on storage.objects
  for select to authenticated using (bucket_id = 'profile-photos');

create policy "allow authenticated profile photo uploads" on storage.objects
  for insert to authenticated with check (bucket_id = 'profile-photos');

create policy "allow authenticated profile photo updates" on storage.objects
  for update to authenticated using (bucket_id = 'profile-photos') with check (bucket_id = 'profile-photos');

create policy "allow authenticated profile photo deletes" on storage.objects
  for delete to authenticated using (bucket_id = 'profile-photos');
