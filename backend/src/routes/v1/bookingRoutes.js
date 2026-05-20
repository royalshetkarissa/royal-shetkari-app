const express = require('express');
const router = express.Router();
const bookingController = require('../../controllers/bookingController');
const { verifyToken } = require('../../middleware/auth');

const validate = require('../../middleware/validate');
const { createBookingSchema } = require('../../validators/bookingValidator');

const idempotency = require('../../middleware/idempotency');

router.use(verifyToken);

router.post('/', idempotency(), validate(createBookingSchema), bookingController.createBooking);
router.get('/count', bookingController.getBookingCount);
router.get('/slots', bookingController.getBookedSlots);

module.exports = router;
