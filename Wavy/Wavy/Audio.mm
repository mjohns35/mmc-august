//
//  Audio.cpp
//  Complication
//
//  Created by Spencer Salazar on 8/13/12.
//  Copyright (c) 2012 Spencer Salazar. All rights reserved.
//

#include "Audio.h"
#include "Filepaths.h"

const float SRATE = 44100;
const float BUFFER_SIZE = 256;



void g_callback( Float32 * buffer, UInt32 numFrames, void * userData )
{
    Audio * audio = (Audio *) userData;
    
    audio->callback(buffer, numFrames, userData);
}


void Audio::play()
{
    m_isRecording = false;
    m_fileOut.closeFile();
    m_fileIn.openFile(stlDocumentsFilepath("tmpfile.wav"));
}

void Audio::record()
{
    m_isRecording = true;
    m_fileOut.openFile(stlDocumentsFilepath("tmpfile.wav"), 1, stk::FileWrite::FILE_WAV, stk::Stk::STK_FLOAT32);
}


Audio::Audio()
{
    MoAudio::init(SRATE, BUFFER_SIZE, 2);
    MoAudio::start(g_callback, this);
    
    m_isRecording = false;
    
    m_fileOutBuffer = new CircularBuffer<float>(BUFFER_SIZE*10);
}

Audio::~Audio()
{
    
}

void Audio::callback( Float32 * buffer, UInt32 numFrames, void * userData )
{
    
    for(int i = 0; i < numFrames; i++)
    {
        float inputSample = buffer[i*2];
        float sample = 0;
        
        if(m_fileIn.isOpen() && !m_fileIn.isFinished())
            sample += m_fileIn.tick();
        if(m_fileIn.isFinished())
            m_fileIn.closeFile();
        
        if(m_isRecording)
            m_fileOutBuffer->put(inputSample);
        
        buffer[i*2] = sample;
        buffer[i*2+1] = sample;
    }
    
    if(m_isRecording)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // tell UI thread to write out file
            if(m_isRecording)
            {
                float outSample;
                while(m_fileOutBuffer->get(outSample))
                {
                    m_fileOut.tick(outSample);
                }
            }
        });
    }
}















        










