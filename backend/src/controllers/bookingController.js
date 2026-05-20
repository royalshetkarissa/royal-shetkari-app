const bookingRepository = require('../repositories/bookingRepository');
const AppError = require('../utils/AppError');

exports.createBooking = async (req, res, next) => {
  const { booking_date, booking_time, help_type, mobile } = req.body;
  try {
    await bookingRepository.create({
      userId: req.userId,
      bookingDate: booking_date,
      bookingTime: booking_time,
      helpType: help_type,
      mobile
    });
    res.status(201).json({ success: true, message: 'Booking created successfully', requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to create booking', 500));
  }
};

exports.getBookingCount = async (req, res, next) => {
  try {
    const count = await bookingRepository.getCount();
    res.json({ success: true, count, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch booking count', 500));
  }
};

exports.getBookedSlots = async (req, res, next) => {
  const { date } = req.query;
  if (!date) return next(new AppError('Date is required', 400));
  
  try {
    const slots = await bookingRepository.getBookedSlotsByDate(date);
    res.json({ success: true, slots, requestId: req.id });
  } catch (error) {
    next(new AppError('Failed to fetch booked slots', 500));
  }
};
