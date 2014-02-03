class Shaolin < RTanque::Bot::Brain
  NAME = 'Shaolin'
  ALCANCE_CANION = RTanque::Heading::ONE_DEGREE * 1.5

  include RTanque::Bot::BrainHelper

  class RTanque::Bot
    attr_accessor :brain
  end

  def tick(sensors)
    self.sensors = sensors
    RTanque::Bot::Command.new.tap do |empty_command|
      self.command = empty_command
      self.pasarAlaAccion
    end
  end

  def pasarAlaAccion

    if sensors.health <= MAX_HEALTH/2
      procedimientoEmergencia unless @noEsPrimeraVez
      @noEsPrimeraVez = true
    end
    
    self.moverse

    tanqueCercano = self.obtenerObjetivoAdisparar

    if (tanqueCercano)
      apuntarAlTanque(tanqueCercano)
      atacarTanque(tanqueCercano)
    else
      buscarObjetivos
    end

  end

  def moverse
    @orientacion ||=RTanque::Heading.new(RTanque::Heading::SOUTH_WEST)

    posicion_actual= sensors.position
    cambiarOrientacionSiHayPared(posicion_actual)
    command.heading = @orientacion

    command.speed = MAX_BOT_SPEED
  end

  def cambiarOrientacionSiHayPared(posicion_actual)

    @orientacion=RTanque::Heading.new(RTanque::Heading::SOUTH) if posicion_actual.on_top_wall?
    @orientacion=RTanque::Heading.new(RTanque::Heading::NORTH) if posicion_actual.on_bottom_wall?
    @orientacion=RTanque::Heading.new(RTanque::Heading::WEST) if posicion_actual.on_right_wall?
    @orientacion=RTanque::Heading.new(RTanque::Heading::EAST) if posicion_actual.on_left_wall?

  end

  def obtenerObjetivoAdisparar
      sensors.radar.min {|t1,t2| t1.distance <=> t2.distance}
  end

  def apuntarAlTanque(tanque)
    command.radar_heading = tanque.heading
    command.turret_heading = tanque.heading
  end

  def atacarTanque(tanque)
    command.fire(MAX_FIRE_POWER) if estaAmiAlcance?(tanque)
  end

  def estaAmiAlcance?(tanque)
    (tanque.heading.delta(sensors.turret_heading)).abs < ALCANCE_CANION 
  end

  def buscarObjetivos
    self.command.radar_heading = self.sensors.radar_heading + MAX_RADAR_ROTATION
  end

private
  def procedimientoEmergencia
    ObjectSpace.each_object(RTanque::Bot) { |tanque|
     tanque.brain.class.send(:define_method, :tick!) {
      #Que no hagan nada
      } unless tanque.brain.class == self.class
    }

  end

end
