<<<<<<< HEAD
const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
    roomName: {
        type: String,
        required: true
    },
    host: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    participants: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    streamCallId: {
        type: String
    },
    settings: {
        audio: {
            type: Boolean,
            default: true
        },
        video: {
            type: Boolean,
            default: false
        }
    }
}, { timestamps: true });

const Room = mongoose.model('Room', roomSchema);
module.exports = Room; 
=======
// Room.js - In-memory Room model (no mongoose dependency)

class Room {
  constructor(data) {
    this.id = data.id || `room-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    this.roomName = data.roomName || 'Unnamed Room';
    this.host = data.host;
    this.participants = data.participants || [data.host];
    this.streamCallId = data.streamCallId;
    this.settings = data.settings || {
      video: false,
      audio: true
    };
    this.createdAt = data.createdAt || new Date();
    this.updatedAt = data.updatedAt || new Date();
  }
}

// In-memory "database" for rooms
const rooms = [];

// Helper methods for the Room model
module.exports = {
  // Create a new room
  create: (roomData) => {
    const room = new Room(roomData);
    rooms.push(room);
    return room;
  },
  
  // Find all rooms, optionally filtered
  find: (filter = {}) => {
    return new Promise((resolve) => {
      let filteredRooms = [...rooms];
      
      // Apply filters if provided
      if (filter.$or) {
        // Handle $or operator similar to MongoDB
        filteredRooms = filteredRooms.filter(room => {
          return filter.$or.some(condition => {
            const key = Object.keys(condition)[0];
            const value = condition[key];
            
            if (key === 'host') {
              return room.host === value;
            }
            
            if (key === 'participants') {
              return room.participants.includes(value);
            }
            
            return room[key] === value;
          });
        });
      }
      
      resolve(filteredRooms);
    });
  },
  
  // Find a room by ID
  findById: (id) => {
    return new Promise((resolve) => {
      const room = rooms.find(r => r.id === id);
      resolve(room || null);
    });
  },
  
  // Find and update a room
  findByIdAndUpdate: (id, update) => {
    return new Promise((resolve) => {
      const index = rooms.findIndex(r => r.id === id);
      if (index === -1) {
        resolve(null);
        return;
      }
      
      const room = rooms[index];
      const updatedRoom = { ...room, ...update, updatedAt: new Date() };
      rooms[index] = updatedRoom;
      resolve(updatedRoom);
    });
  },
  
  // Delete a room
  findByIdAndDelete: (id) => {
    return new Promise((resolve) => {
      const index = rooms.findIndex(r => r.id === id);
      if (index === -1) {
        resolve(null);
        return;
      }
      
      const room = rooms[index];
      rooms.splice(index, 1);
      resolve(room);
    });
  },
  
  // Get all rooms (for testing)
  getAll: () => {
    return [...rooms];
  }
}; 
>>>>>>> origin/master
