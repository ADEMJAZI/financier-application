const mongoose = require('mongoose');

const businessSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Business owner is required'],
    },
    name: {
      type: String,
      required: [true, 'Business name is required'],
    },
    type: {
      type: String,
      required: [true, 'Business type is required'],
    },
    businessType: {
      type: String,
      enum: ['manufacturing', 'resale'],
      required: [true, 'Business type (manufacturing/resale) is required'],
    },
    location: {
      type: String,
      required: [true, 'Business location is required'],
    },
    description: {
      type: String,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Business', businessSchema);
