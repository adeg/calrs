-- When a booking was first confirmed (#266).
--
-- The additional attendees a guest invites get the "you've been added"
-- email, with the invite, once: when the booking becomes confirmed, at
-- submit or at the host's approval. A guest reschedule on an event type
-- that requires confirmation sends the booking back to pending, and its
-- approval looks exactly like the approval of a new request unless the
-- booking remembers it was confirmed before. Without that, attendees were
-- emailed again on every reschedule approval.
--
-- Set by the triggers below on every path that confirms a booking (web
-- booking, approval, CLI), so no call site has to remember it.
--
-- Backfill: bookings confirmed today are stamped with their creation time.
-- A pending booking that was confirmed once and is now awaiting approval of
-- a reschedule cannot be told apart from a new request, and stays NULL: its
-- attendees get the email one more time when it is approved.
ALTER TABLE bookings ADD COLUMN first_confirmed_at TEXT;
UPDATE bookings SET first_confirmed_at = created_at WHERE status = 'confirmed';
CREATE TRIGGER booking_first_confirmed_insert AFTER INSERT ON bookings
WHEN NEW.status = 'confirmed' AND NEW.first_confirmed_at IS NULL
BEGIN UPDATE bookings SET first_confirmed_at = datetime('now') WHERE id = NEW.id; END;
CREATE TRIGGER booking_first_confirmed_update AFTER UPDATE OF status ON bookings
WHEN NEW.status = 'confirmed' AND NEW.first_confirmed_at IS NULL
BEGIN UPDATE bookings SET first_confirmed_at = datetime('now') WHERE id = NEW.id; END;
